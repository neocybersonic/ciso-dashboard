# core/middleware.py
import re
from django.conf import settings
from django.shortcuts import redirect
from django.urls import reverse
from django.utils.deprecation import MiddlewareMixin
from django.http import HttpResponseForbidden

# ==== Public/exempt endpoints (no auth required) ====
EXEMPT_PATHS = [
    r"^/accounts/login/?$",
    r"^/accounts/logout/?$",
    r"^/admin/login/?$",   # allow admin login page unauthenticated
    r"^/static/.*$",       # static files
    r"^/healthz/?$",       # health check
]
EXEMPT_REGEXES = [re.compile(p) for p in EXEMPT_PATHS]

# ==== Write exemptions (allow POST even if not admin) ====
WRITE_EXEMPT_PATHS = [
    r"^/accounts/login/?$",
    r"^/accounts/logout/?$",
    r"^/accounts/password_.*$",
    r"^/admin/.*$",        # admin auth/forms
]
WRITE_EXEMPT_REGEXES = [re.compile(p) for p in WRITE_EXEMPT_PATHS]


class LoginRequiredMiddleware(MiddlewareMixin):
    """
    Redirect unauthenticated users to LOGIN_URL, except for EXEMPT endpoints.
    NOTE: Ensure AuthenticationMiddleware is BEFORE this middleware.
    """
    def process_request(self, request):
        path = request.path

        # Allow exempt paths (login, static, health, etc.)
        for rx in EXEMPT_REGEXES:
            if rx.match(path):
                return None

        # Require auth everywhere else
        if not request.user.is_authenticated:
            login_url = reverse(settings.LOGIN_URL)
            return redirect(f"{login_url}?next={request.path}")

        return None


class ReadOnlyRoleMiddleware(MiddlewareMixin):
    """
    Block write methods (POST/PUT/PATCH/DELETE) unless the user is admin/superuser.
    Allow writes to auth/admin endpoints so login/logout/admin forms work.
    """
    SAFE_METHODS = {"GET", "HEAD", "OPTIONS"}

    def process_view(self, request, view_func, view_args, view_kwargs):
        # Always allow safe methods
        if request.method in self.SAFE_METHODS:
            return None

        path = request.path

        # Allow auth/admin endpoints to write (e.g., POST /login)
        for rx in WRITE_EXEMPT_REGEXES:
            if rx.match(path):
                return None

        user = request.user

        # Block unauthenticated writes elsewhere
        if not user.is_authenticated:
            return HttpResponseForbidden("Write operations are restricted to admin users.")

        # Admins/superusers can write
        if user.is_superuser or user.groups.filter(name="admin").exists():
            return None

        # Everyone else is read-only
        return HttpResponseForbidden("Write operations are restricted to admin users.")
