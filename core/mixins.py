from django.http import HttpResponseForbidden
from django.views.generic.edit import ModelFormMixin
from .features import feature_enabled

class FeatureRequiredMixin:
    feature_key = None  # e.g., "risks"

    def dispatch(self, request, *args, **kwargs):
        if self.feature_key and not feature_enabled(getattr(request, "org", None), self.feature_key):
            return HttpResponseForbidden("Feature disabled.")
        return super().dispatch(request, *args, **kwargs)


class OrgScopedQuerysetMixin:
    """Ensure list/detail views are scoped to the current org."""
    def get_queryset(self):
        qs = super().get_queryset()
        org = getattr(self.request, "org", None)
        if org and hasattr(qs.model, "org"):
            return qs.filter(org=org)
        return qs.none()  # if org required and missing


class OrgFormMixin(ModelFormMixin):
    """Ensure forms save with the current org."""
    def form_valid(self, form):
        if hasattr(form.instance, "org") and getattr(form.instance, "org", None) is None:
            form.instance.org = getattr(self.request, "org", None)
        return super().form_valid(form)
