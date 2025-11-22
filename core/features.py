from django.conf import settings
from .models import FeatureFlag, Organization

DEFAULTS = {
    "risks": True,
    "controls": True,
}

def feature_enabled(org: Organization | None, key: str) -> bool:
    # 1) Per-customer DB override (if org known)
    if org:
        ff = FeatureFlag.objects.filter(org=org, key=key).values_list("enabled", flat=True).first()
        if ff is not None:
            return bool(ff)
    # 2) Project-wide settings
    if hasattr(settings, "CISO_FEATURES"):
        if key in settings.CISO_FEATURES:
            return bool(settings.CISO_FEATURES[key])
    # 3) Defaults
    return DEFAULTS.get(key, False)
