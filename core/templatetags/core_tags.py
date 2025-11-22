from django import template
from core.features import feature_enabled

register = template.Library()

@register.simple_tag(takes_context=True)
def has_feature(context, key):
    request = context["request"]
    org = getattr(request, "org", None)
    return feature_enabled(org, key)
