#!/usr/bin/env bash
set -euo pipefail

echo "==> Scaffolding CREATE views/forms/templates for controls, risks, intelligence..."

########################################
# INTELLIGENCE APP (Asset/Identity/Location create)
########################################
APP="intelligence"
if [ ! -d "$APP" ]; then
  echo "ERROR: intelligence app not found. Run your intelligence scaffold first."
  exit 1
fi

mkdir -p "$APP/templates/$APP"

echo "==> Intelligence: forms.py"
cat > "$APP/forms.py" <<'PY'
from django import forms
from .models import Asset, Identity, Location

class AssetForm(forms.ModelForm):
    class Meta:
        model = Asset
        fields = "__all__"

class IdentityForm(forms.ModelForm):
    class Meta:
        model = Identity
        fields = "__all__"

class LocationForm(forms.ModelForm):
    class Meta:
        model = Location
        fields = "__all__"
PY

echo "==> Intelligence: create views (overwriting views.py with merged content)"
# We will rewrite views.py to include existing list/detail + new create.
cat > "$APP/views.py" <<'PY'
from django.urls import reverse_lazy
from django.views.generic import ListView, DetailView, TemplateView, CreateView
from .models import (
    Asset, Identity, Group, Environment, Location,
    BusinessService, Team, EntityRelationship, SyncRun
)
from .forms import AssetForm, IdentityForm, LocationForm


# ---------------------------
# Dashboard landing page
# ---------------------------
class IntelligenceDashboard(TemplateView):
    template_name = "intelligence/dashboard.html"


# ---------------------------
# ListView base w/ headers
# ---------------------------
class ListWithHeaders(ListView):
    headers = []

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx["headers"] = self.headers
        return ctx


# ---- Lists ----
class AssetList(ListWithHeaders):
    model = Asset
    template_name = "intelligence/asset_list.html"
    paginate_by = 50
    ordering = ["type", "name"]
    headers = ["Name", "Type", "Criticality", "Data Class", "Owner Team",
               "Environment", "Location", "State", "Updated"]


class IdentityList(ListWithHeaders):
    model = Identity
    template_name = "intelligence/identity_list.html"
    paginate_by = 50
    ordering = ["type", "display_name", "username"]
    headers = ["Name", "Username", "Email", "Type", "Status",
               "Owner Team", "Last Login", "Updated"]


class GroupList(ListWithHeaders):
    model = Group
    template_name = "intelligence/group_list.html"
    paginate_by = 50
    ordering = ["type", "name"]
    headers = ["Name", "Type", "Owner Team", "State", "Updated"]


class EnvironmentList(ListWithHeaders):
    model = Environment
    template_name = "intelligence/environment_list.html"
    paginate_by = 50
    ordering = ["type", "name"]
    headers = ["Name", "Type", "Region", "Network Zone", "Owner Team",
               "Criticality", "State", "Updated"]


class LocationList(ListWithHeaders):
    model = Location
    template_name = "intelligence/location_list.html"
    paginate_by = 50
    ordering = ["type", "name"]
    headers = ["Name", "Type", "City", "State/Region", "Country",
               "Tier", "State", "Updated"]


class BusinessServiceList(ListWithHeaders):
    model = BusinessService
    template_name = "intelligence/businessservice_list.html"
    paginate_by = 50
    ordering = ["name"]
    headers = ["Name", "Owner Team", "Criticality", "Updated"]


class TeamList(ListWithHeaders):
    model = Team
    template_name = "intelligence/team_list.html"
    paginate_by = 50
    ordering = ["name"]
    headers = ["Name", "Parent Team", "Criticality", "Updated"]


class RelationshipList(ListWithHeaders):
    model = EntityRelationship
    template_name = "intelligence/relationship_list.html"
    paginate_by = 100
    ordering = ["-updated_at"]
    headers = ["From Type", "From ID", "Relationship", "To Type",
               "To ID", "Source", "Confidence", "Updated"]


class SyncRunList(ListWithHeaders):
    model = SyncRun
    template_name = "intelligence/syncrun_list.html"
    paginate_by = 50
    ordering = ["-started_at"]
    headers = ["Source", "Started", "Finished", "Success", "Summary"]


# ---- Details ----
class AssetDetail(DetailView):
    model = Asset
    template_name = "intelligence/asset_detail.html"


class IdentityDetail(DetailView):
    model = Identity
    template_name = "intelligence/identity_detail.html"


class GroupDetail(DetailView):
    model = Group
    template_name = "intelligence/group_detail.html"


class EnvironmentDetail(DetailView):
    model = Environment
    template_name = "intelligence/environment_detail.html"


class LocationDetail(DetailView):
    model = Location
    template_name = "intelligence/location_detail.html"


class BusinessServiceDetail(DetailView):
    model = BusinessService
    template_name = "intelligence/businessservice_detail.html"


class TeamDetail(DetailView):
    model = Team
    template_name = "intelligence/team_detail.html"


# ---- Creates ----
class AssetCreate(CreateView):
    model = Asset
    form_class = AssetForm
    template_name = "intelligence/asset_form.html"
    success_url = reverse_lazy("intelligence:asset_list")


class IdentityCreate(CreateView):
    model = Identity
    form_class = IdentityForm
    template_name = "intelligence/identity_form.html"
    success_url = reverse_lazy("intelligence:identity_list")


class LocationCreate(CreateView):
    model = Location
    form_class = LocationForm
    template_name = "intelligence/location_form.html"
    success_url = reverse_lazy("intelligence:location_list")
PY

echo "==> Intelligence: urls.py (overwriting with create routes added)"
cat > "$APP/urls.py" <<'PY'
from django.urls import path
from . import views

app_name = "intelligence"

urlpatterns = [
    path("", views.IntelligenceDashboard.as_view(), name="dashboard"),

    # Assets
    path("assets/", views.AssetList.as_view(), name="asset_list"),
    path("assets/add/", views.AssetCreate.as_view(), name="asset_add"),
    path("assets/<uuid:pk>/", views.AssetDetail.as_view(), name="asset_detail"),

    # Identities
    path("identities/", views.IdentityList.as_view(), name="identity_list"),
    path("identities/add/", views.IdentityCreate.as_view(), name="identity_add"),
    path("identities/<uuid:pk>/", views.IdentityDetail.as_view(), name="identity_detail"),

    # Groups
    path("groups/", views.GroupList.as_view(), name="group_list"),
    path("groups/<uuid:pk>/", views.GroupDetail.as_view(), name="group_detail"),

    # Environments
    path("environments/", views.EnvironmentList.as_view(), name="environment_list"),
    path("environments/<uuid:pk>/", views.EnvironmentDetail.as_view(), name="environment_detail"),

    # Locations
    path("locations/", views.LocationList.as_view(), name="location_list"),
    path("locations/add/", views.LocationCreate.as_view(), name="location_add"),
    path("locations/<uuid:pk>/", views.LocationDetail.as_view(), name="location_detail"),

    # Business services
    path("business-services/", views.BusinessServiceList.as_view(), name="businessservice_list"),
    path("business-services/<uuid:pk>/", views.BusinessServiceDetail.as_view(), name="businessservice_detail"),

    # Teams
    path("teams/", views.TeamList.as_view(), name="team_list"),
    path("teams/<uuid:pk>/", views.TeamDetail.as_view(), name="team_detail"),

    # Relationships
    path("relationships/", views.RelationshipList.as_view(), name="relationship_list"),

    # Sync runs
    path("sync-runs/", views.SyncRunList.as_view(), name="syncrun_list"),
]
PY

echo "==> Intelligence: shared form template"
cat > "$APP/templates/$APP/_form_base.html" <<'HTML'
{% extends "base.html" %}
{% load widget_tweaks %}
{% block content %}
<div class="mx-auto max-w-3xl p-6">
  <div class="mb-6">
    <h1 class="text-2xl font-semibold text-slate-900 dark:text-slate-100">{{ title }}</h1>
    <p class="text-slate-600 dark:text-slate-300 mt-1">{{ subtitle }}</p>
  </div>

  <form method="post" class="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl shadow-sm p-6 space-y-5">
    {% csrf_token %}
    {{ form.non_field_errors }}

    {% for field in form %}
      <div>
        <label class="block text-sm font-medium text-slate-700 dark:text-slate-200 mb-1">{{ field.label }}</label>
        {% if field.field.widget.input_type == "checkbox" %}
          {{ field|add_class:"h-4 w-4 rounded border-slate-300 dark:border-slate-600" }}
        {% else %}
          {{ field|add_class:"w-full rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-slate-900 dark:text-slate-100 px-3 py-2 focus:outline-none focus:ring focus:ring-indigo-300 dark:focus:ring-indigo-700" }}
        {% endif %}
        {% if field.help_text %}
          <p class="mt-1 text-xs text-slate-500 dark:text-slate-400">{{ field.help_text }}</p>
        {% endif %}
        {% for e in field.errors %}
          <p class="mt-1 text-xs text-red-600 dark:text-red-400">{{ e }}</p>
        {% endfor %}
      </div>
    {% endfor %}

    <div class="flex gap-2 pt-2">
      <button type="submit" class="px-4 py-2 rounded-lg bg-indigo-600 hover:bg-indigo-700 text-white shadow-sm">
        Save
      </button>
      <a href="{{ cancel_url }}" class="px-4 py-2 rounded-lg bg-slate-200 dark:bg-slate-700 text-slate-900 dark:text-slate-100">
        Cancel
      </a>
    </div>
  </form>
</div>
{% endblock %}
HTML

echo "==> Intelligence: asset/identity/location form templates"
cat > "$APP/templates/$APP/asset_form.html" <<'HTML'
{% include "intelligence/_form_base.html" with title="Add Asset" subtitle="Create a new asset record" cancel_url="{% url 'intelligence:asset_list' %}" %}
HTML

cat > "$APP/templates/$APP/identity_form.html" <<'HTML'
{% include "intelligence/_form_base.html" with title="Add Identity" subtitle="Create a new identity record" cancel_url="{% url 'intelligence:identity_list' %}" %}
HTML

cat > "$APP/templates/$APP/location_form.html" <<'HTML'
{% include "intelligence/_form_base.html" with title="Add Location" subtitle="Create a new location record" cancel_url="{% url 'intelligence:location_list' %}" %}
HTML

########################################
# CONTROLS APP (Control create)
########################################
APP="controls"
if [ ! -d "$APP" ]; then
  echo "ERROR: controls app not found."
  exit 1
fi

mkdir -p "$APP/templates/$APP"

echo "==> Controls: forms.py"
cat > "$APP/forms.py" <<'PY'
from django import forms
from .models import Control

class ControlForm(forms.ModelForm):
    class Meta:
        model = Control
        fields = "__all__"
PY

echo "==> Controls: create view appended file (create_views.py to avoid clobbering)"
cat > "$APP/create_views.py" <<'PY'
from django.urls import reverse_lazy
from django.views.generic import CreateView
from .models import Control
from .forms import ControlForm

class ControlCreate(CreateView):
    model = Control
    form_class = ControlForm
    template_name = "controls/control_form.html"
    success_url = reverse_lazy("controls:control_list")
PY

echo "==> Controls: control_form.html"
cat > "$APP/templates/$APP/control_form.html" <<'HTML'
{% extends "base.html" %}
{% load widget_tweaks %}
{% block content %}
<div class="mx-auto max-w-3xl p-6">
  <h1 class="text-2xl font-semibold text-slate-900 dark:text-slate-100 mb-6">Add Control</h1>

  <form method="post" class="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl shadow-sm p-6 space-y-5">
    {% csrf_token %}
    {{ form.non_field_errors }}

    {% for field in form %}
      <div>
        <label class="block text-sm font-medium text-slate-700 dark:text-slate-200 mb-1">{{ field.label }}</label>
        {% if field.field.widget.input_type == "checkbox" %}
          {{ field|add_class:"h-4 w-4 rounded border-slate-300 dark:border-slate-600" }}
        {% else %}
          {{ field|add_class:"w-full rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-slate-900 dark:text-slate-100 px-3 py-2 focus:outline-none focus:ring focus:ring-indigo-300 dark:focus:ring-indigo-700" }}
        {% endif %}
        {% if field.help_text %}
          <p class="mt-1 text-xs text-slate-500 dark:text-slate-400">{{ field.help_text }}</p>
        {% endif %}
        {% for e in field.errors %}
          <p class="mt-1 text-xs text-red-600 dark:text-red-400">{{ e }}</p>
        {% endfor %}
      </div>
    {% endfor %}

    <div class="flex gap-2 pt-2">
      <button type="submit" class="px-4 py-2 rounded-lg bg-indigo-600 hover:bg-indigo-700 text-white shadow-sm">Save</button>
      <a href="{% url 'controls:control_list' %}" class="px-4 py-2 rounded-lg bg-slate-200 dark:bg-slate-700 text-slate-900 dark:text-slate-100">Cancel</a>
    </div>
  </form>
</div>
{% endblock %}
HTML

########################################
# RISKS APP (Risk create)
########################################
APP="risks"
if [ ! -d "$APP" ]; then
  echo "ERROR: risks app not found."
  exit 1
fi

mkdir -p "$APP/templates/$APP"

echo "==> Risks: forms.py"
cat > "$APP/forms.py" <<'PY'
from django import forms
from .models import Risk

class RiskForm(forms.ModelForm):
    class Meta:
        model = Risk
        fields = "__all__"
PY

echo "==> Risks: create view in create_views.py"
cat > "$APP/create_views.py" <<'PY'
from django.urls import reverse_lazy
from django.views.generic import CreateView
from .models import Risk
from .forms import RiskForm

class RiskCreate(CreateView):
    model = Risk
    form_class = RiskForm
    template_name = "risks/risk_form.html"
    success_url = reverse_lazy("risks:risk_list")
PY

echo "==> Risks: risk_form.html"
cat > "$APP/templates/$APP/risk_form.html" <<'HTML'
{% extends "base.html" %}
{% load widget_tweaks %}
{% block content %}
<div class="mx-auto max-w-3xl p-6">
  <h1 class="text-2xl font-semibold text-slate-900 dark:text-slate-100 mb-6">Add Risk</h1>

  <form method="post" class="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl shadow-sm p-6 space-y-5">
    {% csrf_token %}
    {{ form.non_field_errors }}

    {% for field in form %}
      <div>
        <label class="block text-sm font-medium text-slate-700 dark:text-slate-200 mb-1">{{ field.label }}</label>
        {% if field.field.widget.input_type == "checkbox" %}
          {{ field|add_class:"h-4 w-4 rounded border-slate-300 dark:border-slate-600" }}
        {% else %}
          {{ field|add_class:"w-full rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-slate-900 dark:text-slate-100 px-3 py-2 focus:outline-none focus:ring focus:ring-indigo-300 dark:focus:ring-indigo-700" }}
        {% endif %}
        {% if field.help_text %}
          <p class="mt-1 text-xs text-slate-500 dark:text-slate-400">{{ field.help_text }}</p>
        {% endif %}
        {% for e in field.errors %}
          <p class="mt-1 text-xs text-red-600 dark:text-red-400">{{ e }}</p>
        {% endfor %}
      </div>
    {% endfor %}

    <div class="flex gap-2 pt-2">
      <button type="submit" class="px-4 py-2 rounded-lg bg-indigo-600 hover:bg-indigo-700 text-white shadow-sm">Save</button>
      <a href="{% url 'risks:risk_list' %}" class="px-4 py-2 rounded-lg bg-slate-200 dark:bg-slate-700 text-slate-900 dark:text-slate-100">Cancel</a>
    </div>
  </form>
</div>
{% endblock %}
HTML

echo ""
echo "==> Scaffold complete."
echo ""
echo "MANUAL UPDATES NEEDED:"
cat <<'INSTR'

1) controls/urls.py
   - import the create view:
       from .create_views import ControlCreate
   - add a route BEFORE the <pk> detail route:
       path("add/", ControlCreate.as_view(), name="control_add"),

2) controls/views.py (controls list page)
   - add a button in your control_list.html template near top:
       <a href="{% url 'controls:control_add' %}" class="px-3 py-2 rounded-lg bg-indigo-600 text-white hover:bg-indigo-700">
         + Add Control
       </a>

3) risks/urls.py
   - import:
       from .create_views import RiskCreate
   - add:
       path("add/", RiskCreate.as_view(), name="risk_add"),

4) risks/templates/risks/risk_list.html
   - add button near top:
       <a href="{% url 'risks:risk_add' %}" class="px-3 py-2 rounded-lg bg-indigo-600 text-white hover:bg-indigo-700">
         + Add Risk
       </a>

5) intelligence list templates (top buttons)
   Add these buttons near the title area:
     - intelligence/asset_list.html:
         <a href="{% url 'intelligence:asset_add' %}" class="px-3 py-2 rounded-lg bg-indigo-600 text-white hover:bg-indigo-700">+ Add Asset</a>
     - intelligence/identity_list.html:
         <a href="{% url 'intelligence:identity_add' %}" class="px-3 py-2 rounded-lg bg-indigo-600 text-white hover:bg-indigo-700">+ Add Identity</a>
     - intelligence/location_list.html:
         <a href="{% url 'intelligence:location_add' %}" class="px-3 py-2 rounded-lg bg-indigo-600 text-white hover:bg-indigo-700">+ Add Location</a>

6) If you don't already have widget_tweaks installed for ALL apps:
   - add "widget_tweaks" to INSTALLED_APPS.
   - pip install django-widget-tweaks

INSTR
