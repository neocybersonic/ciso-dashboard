# core/templatetags/user_extras.py
from django import template

register = template.Library()

@register.filter
def initials(user):
    """
    Returns initials from first/last name if available, else from username.
    """
    try:
        fn = (getattr(user, "first_name", "") or "").strip()
        ln = (getattr(user, "last_name", "") or "").strip()
        if fn or ln:
            return ((fn[:1] or "") + (ln[:1] or "")).upper()
        uname = (getattr(user, "username", "") or "").strip()
        if uname:
            parts = uname.replace("_", " ").replace(".", " ").split()
            if parts:
                if len(parts) >= 2:
                    return (parts[0][:1] + parts[1][:1]).upper()
                return parts[0][:2].upper()
        return "U"
    except Exception:
        return "U"
