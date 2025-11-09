from django.shortcuts import render
from django.http import HttpResponse

# core/views.py
from django.contrib.auth import get_user_model
from django.contrib.auth.mixins import LoginRequiredMixin
from django.urls import reverse_lazy
from django.views.generic import DetailView, UpdateView

def healthz(request):
    return HttpResponse("ok")

def home(request):
    """
    Blank landing page with top bar + left sidebar.
    Shows Login/Logout appropriately.
    """
    return render(request, "home.html")

User = get_user_model()

class CurrentUserMixin(LoginRequiredMixin):
    """Operate on the authenticated user; no pk in URL."""
    def get_object(self, queryset=None):
        return self.request.user

class ProfileDetailView(LoginRequiredMixin, DetailView):
    """Shows the *current* user's record (no pk in URL)."""
    model = User
    template_name = "core/profile.html"
    context_object_name = "user_obj"

    def get_object(self, queryset=None):
        return self.request.user

# OPTIONAL: enable when ready to edit safe fields
class ProfileUpdateView(CurrentUserMixin, UpdateView):
    model = User
    fields = ["first_name", "last_name", "email"]  # keep this conservative
    template_name = "core/profile_form.html"
    success_url = reverse_lazy("core:profile")





