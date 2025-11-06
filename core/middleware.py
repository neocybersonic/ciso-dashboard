import re
from django.conf import settings
from django.shortcuts import redirect
from django.urls import reverse
from django.utils.deprecation import MiddlewareMixin
from django.http import HttpResponseForbidden

EXEMPT_PATHS = [
    r"^/login/?$",
    r"^/logout/?$",
    r"^/admin/login/?$",
    r"^/static/.*$",
    r"^/healthz/?$",
]

EXEMPT_REGEXES = [re.compile(p) for p in EXEMPT_PATHS]

EXEMPT_URL_NAMES = {"login", "logout", "admin:login"}  # allow login + admin login
EXEMPT_PATH_PREFIXES = {"/static/", "/healthz"}        # allow static/health

class LoginRequiredMiddleware(MiddlewareMixin):
    def process_request(self, request):
        path = request.path

        # Allow exempt paths
        for rx in EXEMPT_REGEXES:
            if rx.match(path):
                return None


        if any(path.startswith(p) for p in EXEMPT_PATH_PREFIXES):
            return None

        try:
            resolved = request.resolver_match
            if resolved and resolved.view_name in EXEMPT_URL_NAMES:
                return None
        except Exception:
            pass

        if not request.user.is_authenticated:
            login_url = reverse(settings.LOGIN_URL)
            return redirect(f"{login_url}?next={request.path}")
        return None
        

class ReadOnlyRoleMiddleware(MiddlewareMixin):
    SAFE_METHODS = {"GET", "HEAD", "OPTIONS"}

    def process_view(self, request, view_func, view_args, view_kwargs):
        # Allow safe methods
        if request.method in self.SAFE_METHODS:
            return None

        # Require admin group for write methods
        user = request.user
        if user.is_authenticated and user.groups.filter(name="admin").exists():
            return None

        return HttpResponseForbidden("Write operations are restricted to admin users.")
