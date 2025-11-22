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
