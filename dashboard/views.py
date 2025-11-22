# dashboard/views.py
from django.shortcuts import render
from core.features import feature_enabled
from controls.models import Control

def home(request):
    org = getattr(request, "org", None)
    failing_controls = []
    if feature_enabled(org, "controls"):
        failing_controls = Control.objects.filter(org=org, status="Failing").order_by("short_description")[:15]
    return render(request, "dashboard/home.html", {"failing_controls": failing_controls})
