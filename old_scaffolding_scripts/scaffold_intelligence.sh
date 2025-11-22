#!/usr/bin/env bash
set -euo pipefail

APP="intelligence"

echo "==> Creating app '$APP' if needed..."
if [ ! -d "$APP" ]; then
  python3 manage.py startapp "$APP"
else
  echo "    App already exists. Continuing and overwriting scaffolded files."
fi

echo "==> Creating directories..."
mkdir -p "$APP/templates/$APP"
mkdir -p "$APP/connectors"
mkdir -p "$APP/migrations"

echo "==> Writing models.py..."
cat > "$APP/models.py" <<'PY'
from __future__ import annotations

import uuid
from django.db import models
from django.utils import timezone


# -------------------------
# Shared / Core primitives
# -------------------------

class TimeStampedModel(models.Model):
    created_at = models.DateTimeField(default=timezone.now, editable=False)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True


class EntityType(models.TextChoices):
    ASSET = "asset", "Asset"
    IDENTITY = "identity", "Identity"
    GROUP = "group", "Group"
    ENVIRONMENT = "environment", "Environment"
    LOCATION = "location", "Location"
    TEAM = "team", "Team"
    BUSINESS_SERVICE = "business_service", "Business Service"


class Criticality(models.TextChoices):
    TIER0 = "tier0", "Tier 0"
    TIER1 = "tier1", "Tier 1"
    TIER2 = "tier2", "Tier 2"
    TIER3 = "tier3", "Tier 3"
    HIGH = "high", "High"
    MEDIUM = "medium", "Medium"
    LOW = "low", "Low"
    UNKNOWN = "unknown", "Unknown"


class LifecycleState(models.TextChoices):
    PLANNED = "planned", "Planned"
    ACTIVE = "active", "Active"
    DEPRECATED = "deprecated", "Deprecated"
    RETIRED = "retired", "Retired"
    STALE = "stale", "Stale"


class SourceSystem(models.TextChoices):
    SERVICENOW = "servicenow", "ServiceNow"
    FLEXERA = "flexera", "Flexera"
    AD = "active_directory", "Active Directory"
    OKTA = "okta", "Okta"
    DUO = "duo", "Duo"
    AWS = "aws", "AWS"
    AZURE = "azure", "Azure"
    GCP = "gcp", "GCP"
    MANUAL = "manual", "Manual"
    OTHER = "other", "Other"


class ExternalID(TimeStampedModel):
    """
    Generic place to store any external/system IDs per entity.
    Example: ServiceNow sys_id, AWS ARN, Okta id, AD objectGUID, etc.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    entity_type = models.CharField(max_length=64, choices=EntityType.choices)
    entity_uuid = models.UUIDField()
    source = models.CharField(max_length=64, choices=SourceSystem.choices)
    external_id = models.CharField(max_length=256)
    external_id_type = models.CharField(max_length=128, blank=True, default="")

    class Meta:
        unique_together = ("entity_type", "entity_uuid", "source", "external_id")
        indexes = [
            models.Index(fields=["entity_type", "entity_uuid"]),
            models.Index(fields=["source", "external_id"]),
        ]

    def __str__(self):
        return f"{self.entity_type}:{self.entity_uuid} -> {self.source}:{self.external_id}"


# -------------------------
# Ownership / business context
# -------------------------

class Team(TimeStampedModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=200, unique=True)
    description = models.TextField(blank=True, default="")
    parent_team = models.ForeignKey("self", null=True, blank=True, on_delete=models.SET_NULL, related_name="child_teams")

    criticality = models.CharField(max_length=32, choices=Criticality.choices, default=Criticality.UNKNOWN)

    def __str__(self):
        return self.name


class BusinessService(TimeStampedModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=200, unique=True)
    description = models.TextField(blank=True, default="")
    owner_team = models.ForeignKey(Team, null=True, blank=True, on_delete=models.SET_NULL, related_name="business_services")
    criticality = models.CharField(max_length=32, choices=Criticality.choices, default=Criticality.UNKNOWN)

    def __str__(self):
        return self.name


# -------------------------
# Environment + Location
# -------------------------

class Environment(TimeStampedModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    type = models.CharField(max_length=64, help_text="aws_account, azure_subscription, gcp_project, k8s_cluster, onprem_zone, etc.")
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True, default="")

    parent_environment = models.ForeignKey("self", null=True, blank=True, on_delete=models.SET_NULL, related_name="child_environments")

    region = models.CharField(max_length=128, blank=True, default="")
    network_zone = models.CharField(max_length=128, blank=True, default="")

    owner_team = models.ForeignKey(Team, null=True, blank=True, on_delete=models.SET_NULL, related_name="environments")
    criticality = models.CharField(max_length=32, choices=Criticality.choices, default=Criticality.UNKNOWN)

    lifecycle_state = models.CharField(max_length=32, choices=LifecycleState.choices, default=LifecycleState.ACTIVE)

    last_seen_at = models.DateTimeField(null=True, blank=True)
    first_seen_at = models.DateTimeField(null=True, blank=True)

    source_of_truth = models.CharField(max_length=64, choices=SourceSystem.choices, default=SourceSystem.MANUAL)

    class Meta:
        unique_together = ("type", "name")
        indexes = [
            models.Index(fields=["type"]),
            models.Index(fields=["name"]),
        ]

    def __str__(self):
        return f"{self.name} ({self.type})"


class LocationType(models.TextChoices):
    OFFICE = "office", "Office"
    DATACENTER = "datacenter", "Data Center"
    CLOUD_REGION = "cloud_region", "Cloud Region"
    OTHER = "other", "Other"


class Location(TimeStampedModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    type = models.CharField(max_length=32, choices=LocationType.choices)
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True, default="")

    address = models.CharField(max_length=300, blank=True, default="")
    city = models.CharField(max_length=100, blank=True, default="")
    state_region = models.CharField(max_length=100, blank=True, default="")
    country = models.CharField(max_length=100, blank=True, default="")

    tier = models.CharField(max_length=32, choices=Criticality.choices, default=Criticality.UNKNOWN)
    owner_team = models.ForeignKey(Team, null=True, blank=True, on_delete=models.SET_NULL, related_name="locations")

    lifecycle_state = models.CharField(max_length=32, choices=LifecycleState.choices, default=LifecycleState.ACTIVE)

    class Meta:
        unique_together = ("type", "name")

    def __str__(self):
        return f"{self.name} ({self.type})"


# -------------------------
# Identities + Groups
# -------------------------

class IdentityType(models.TextChoices):
    HUMAN = "human", "Human"
    SERVICE = "service", "Service Account"
    PRIVILEGED = "privileged", "Privileged"
    SHARED = "shared", "Shared"
    BREAK_GLASS = "break_glass", "Break-glass"


class IdentityStatus(models.TextChoices):
    ACTIVE = "active", "Active"
    DISABLED = "disabled", "Disabled"
    PENDING = "pending", "Pending"
    TERMINATED = "terminated", "Terminated"
    STALE = "stale", "Stale"


class Identity(TimeStampedModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    type = models.CharField(max_length=32, choices=IdentityType.choices, default=IdentityType.HUMAN)

    username = models.CharField(max_length=150, blank=True, default="")
    display_name = models.CharField(max_length=200, blank=True, default="")
    email = models.EmailField(blank=True, default="")

    org_unit = models.CharField(max_length=200, blank=True, default="")
    manager_identity = models.ForeignKey("self", null=True, blank=True, on_delete=models.SET_NULL, related_name="direct_reports")

    status = models.CharField(max_length=32, choices=IdentityStatus.choices, default=IdentityStatus.ACTIVE)
    auth_sources = models.JSONField(blank=True, default=list, help_text="e.g. ['AD','Okta','Duo']")
    last_login_at = models.DateTimeField(null=True, blank=True)

    owner_team = models.ForeignKey(Team, null=True, blank=True, on_delete=models.SET_NULL, related_name="identities")
    lifecycle_state = models.CharField(max_length=32, choices=LifecycleState.choices, default=LifecycleState.ACTIVE)

    risk_flags = models.JSONField(blank=True, default=list, help_text="Tags like no_mfa, stale_account, etc.")
    last_seen_at = models.DateTimeField(null=True, blank=True)
    first_seen_at = models.DateTimeField(null=True, blank=True)
    source_of_truth = models.CharField(max_length=64, choices=SourceSystem.choices, default=SourceSystem.MANUAL)

    class Meta:
        indexes = [
            models.Index(fields=["username"]),
            models.Index(fields=["email"]),
            models.Index(fields=["status"]),
        ]

    def __str__(self):
        return self.display_name or self.username or str(self.id)


class GroupType(models.TextChoices):
    AD_GROUP = "ad_group", "AD Group"
    OKTA_GROUP = "okta_group", "Okta Group"
    ROLE = "role", "Role"
    OTHER = "other", "Other"


class Group(TimeStampedModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    type = models.CharField(max_length=32, choices=GroupType.choices, default=GroupType.OTHER)
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True, default="")

    owner_team = models.ForeignKey(Team, null=True, blank=True, on_delete=models.SET_NULL, related_name="groups")
    lifecycle_state = models.CharField(max_length=32, choices=LifecycleState.choices, default=LifecycleState.ACTIVE)
    source_of_truth = models.CharField(max_length=64, choices=SourceSystem.choices, default=SourceSystem.MANUAL)

    members = models.ManyToManyField(Identity, blank=True, related_name="groups")

    class Meta:
        unique_together = ("type", "name")

    def __str__(self):
        return f"{self.name} ({self.type})"


# -------------------------
# Assets
# -------------------------

class AssetType(models.TextChoices):
    ENDPOINT = "endpoint", "Endpoint"
    SERVER = "server", "Server"
    VM = "vm", "Virtual Machine"
    CONTAINER = "container", "Container"
    DATABASE = "database", "Database"
    SAAS_APP = "saas_app", "SaaS App"
    NETWORK_DEVICE = "network_device", "Network Device"
    CODE_REPO = "code_repo", "Code Repo"
    OTHER = "other", "Other"


class DataClassification(models.TextChoices):
    PUBLIC = "public", "Public"
    INTERNAL = "internal", "Internal"
    CONFIDENTIAL = "confidential", "Confidential"
    REGULATED = "regulated", "Regulated"
    PHI = "phi", "PHI"
    PII = "pii", "PII"
    UNKNOWN = "unknown", "Unknown"


class Asset(TimeStampedModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    type = models.CharField(max_length=32, choices=AssetType.choices, default=AssetType.OTHER)
    name = models.CharField(max_length=250)
    description = models.TextField(blank=True, default="")

    owner_person = models.ForeignKey(Identity, null=True, blank=True, on_delete=models.SET_NULL, related_name="owned_assets")
    owner_team = models.ForeignKey(Team, null=True, blank=True, on_delete=models.SET_NULL, related_name="assets")

    business_service = models.ForeignKey(BusinessService, null=True, blank=True, on_delete=models.SET_NULL, related_name="assets")

    location = models.ForeignKey(Location, null=True, blank=True, on_delete=models.SET_NULL, related_name="assets")
    environment = models.ForeignKey(Environment, null=True, blank=True, on_delete=models.SET_NULL, related_name="assets")

    criticality = models.CharField(max_length=32, choices=Criticality.choices, default=Criticality.UNKNOWN)
    data_classification = models.CharField(max_length=32, choices=DataClassification.choices, default=DataClassification.UNKNOWN)

    lifecycle_state = models.CharField(max_length=32, choices=LifecycleState.choices, default=LifecycleState.ACTIVE)

    last_seen_at = models.DateTimeField(null=True, blank=True)
    first_seen_at = models.DateTimeField(null=True, blank=True)
    source_of_truth = models.CharField(max_length=64, choices=SourceSystem.choices, default=SourceSystem.MANUAL)

    class Meta:
        unique_together = ("type", "name")
        indexes = [
            models.Index(fields=["type"]),
            models.Index(fields=["name"]),
            models.Index(fields=["criticality"]),
        ]

    def __str__(self):
        return f"{self.name} ({self.type})"


# -------------------------
# Relationships (graph)
# -------------------------

class RelationshipType(models.TextChoices):
    RUNS_IN = "runs_in", "Runs in"
    HOSTED_IN = "hosted_in", "Hosted in"
    DEPENDS_ON = "depends_on", "Depends on"
    CONNECTED_TO = "connected_to", "Connected to"
    BACKS_UP = "backs_up", "Backs up"
    PARENT_OF = "parent_of", "Parent of"
    LOCATED_AT = "located_at", "Located at"
    OWNS = "owns", "Owns"
    USES = "uses", "Uses"
    ADMIN_OF = "admin_of", "Admin of"
    HAS_ACCESS_TO = "has_access_to", "Has access to"
    MEMBER_OF = "member_of", "Member of"
    MANAGES = "manages", "Manages"
    ASSUMES_ROLE = "assumes_role", "Assumes role"
    OTHER = "other", "Other"


class EntityRelationship(TimeStampedModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    from_entity_type = models.CharField(max_length=64, choices=EntityType.choices)
    from_entity_id = models.UUIDField()

    to_entity_type = models.CharField(max_length=64, choices=EntityType.choices)
    to_entity_id = models.UUIDField()

    relationship_type = models.CharField(max_length=64, choices=RelationshipType.choices)
    source = models.CharField(max_length=64, choices=SourceSystem.choices, default=SourceSystem.MANUAL)
    confidence = models.FloatField(default=1.0)
    last_confirmed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        indexes = [
            models.Index(fields=["from_entity_type", "from_entity_id"]),
            models.Index(fields=["to_entity_type", "to_entity_id"]),
            models.Index(fields=["relationship_type"]),
        ]

    def __str__(self):
        return f"{self.from_entity_type}:{self.from_entity_id} -[{self.relationship_type}]-> {self.to_entity_type}:{self.to_entity_id}"


# -------------------------
# Raw ingest + sync runs
# -------------------------

class SyncRun(TimeStampedModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    source = models.CharField(max_length=64, choices=SourceSystem.choices)
    started_at = models.DateTimeField(default=timezone.now)
    finished_at = models.DateTimeField(null=True, blank=True)
    success = models.BooleanField(default=False)
    summary = models.TextField(blank=True, default="")
    error = models.TextField(blank=True, default="")

    def __str__(self):
        return f"{self.source} sync @ {self.started_at:%Y-%m-%d %H:%M} ({'ok' if self.success else 'fail'})"


class RawRecord(TimeStampedModel):
    """
    Store raw API payloads for audit/debugging.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    sync_run = models.ForeignKey(SyncRun, null=True, blank=True, on_delete=models.SET_NULL, related_name="raw_records")

    source = models.CharField(max_length=64, choices=SourceSystem.choices)
    record_type = models.CharField(max_length=128, help_text="Class/table/type from source, e.g., cmdb_ci_server")
    external_id = models.CharField(max_length=256, blank=True, default="")
    payload = models.JSONField()

    processed = models.BooleanField(default=False)
    processing_error = models.TextField(blank=True, default="")

    class Meta:
        indexes = [
            models.Index(fields=["source", "record_type"]),
            models.Index(fields=["external_id"]),
            models.Index(fields=["processed"]),
        ]

    def __str__(self):
        return f"{self.source}:{self.record_type}:{self.external_id or self.id}"
PY

echo "==> Writing admin.py..."
cat > "$APP/admin.py" <<'PY'
from django.contrib import admin
from .models import (
    ExternalID,
    Team, BusinessService,
    Environment, Location,
    Identity, Group,
    Asset,
    EntityRelationship,
    SyncRun, RawRecord
)

@admin.register(ExternalID)
class ExternalIDAdmin(admin.ModelAdmin):
    list_display = ("entity_type", "entity_uuid", "source", "external_id", "external_id_type", "updated_at")
    search_fields = ("external_id", "entity_uuid")
    list_filter = ("entity_type", "source")


@admin.register(Team)
class TeamAdmin(admin.ModelAdmin):
    list_display = ("name", "parent_team", "criticality", "updated_at")
    search_fields = ("name",)
    list_filter = ("criticality",)


@admin.register(BusinessService)
class BusinessServiceAdmin(admin.ModelAdmin):
    list_display = ("name", "owner_team", "criticality", "updated_at")
    search_fields = ("name",)
    list_filter = ("criticality",)


@admin.register(Environment)
class EnvironmentAdmin(admin.ModelAdmin):
    list_display = ("name", "type", "region", "network_zone", "owner_team", "criticality", "lifecycle_state", "updated_at")
    search_fields = ("name", "type")
    list_filter = ("type", "criticality", "lifecycle_state")


@admin.register(Location)
class LocationAdmin(admin.ModelAdmin):
    list_display = ("name", "type", "city", "state_region", "country", "tier", "lifecycle_state", "updated_at")
    search_fields = ("name", "city", "country")
    list_filter = ("type", "tier", "lifecycle_state")


@admin.register(Identity)
class IdentityAdmin(admin.ModelAdmin):
    list_display = ("display_name", "username", "email", "type", "status", "owner_team", "last_login_at", "updated_at")
    search_fields = ("display_name", "username", "email")
    list_filter = ("type", "status")


@admin.register(Group)
class GroupAdmin(admin.ModelAdmin):
    list_display = ("name", "type", "owner_team", "lifecycle_state", "updated_at")
    search_fields = ("name",)
    list_filter = ("type", "lifecycle_state")
    filter_horizontal = ("members",)


@admin.register(Asset)
class AssetAdmin(admin.ModelAdmin):
    list_display = ("name", "type", "criticality", "data_classification", "owner_team", "environment", "location", "lifecycle_state", "updated_at")
    search_fields = ("name",)
    list_filter = ("type", "criticality", "data_classification", "lifecycle_state")


@admin.register(EntityRelationship)
class EntityRelationshipAdmin(admin.ModelAdmin):
    list_display = ("from_entity_type", "from_entity_id", "relationship_type", "to_entity_type", "to_entity_id", "source", "confidence", "updated_at")
    list_filter = ("relationship_type", "source")
    search_fields = ("from_entity_id", "to_entity_id")


@admin.register(SyncRun)
class SyncRunAdmin(admin.ModelAdmin):
    list_display = ("source", "started_at", "finished_at", "success")
    list_filter = ("source", "success")
    search_fields = ("summary", "error")


@admin.register(RawRecord)
class RawRecordAdmin(admin.ModelAdmin):
    list_display = ("source", "record_type", "external_id", "processed", "sync_run", "updated_at")
    list_filter = ("source", "record_type", "processed")
    search_fields = ("external_id",)
PY

echo "==> Writing views.py..."
cat > "$APP/views.py" <<'PY'
from django.views.generic import ListView, DetailView
from .models import (
    Asset, Identity, Group, Environment, Location,
    BusinessService, Team, EntityRelationship, SyncRun
)

# ---- Lists ----

class AssetList(ListView):
    model = Asset
    template_name = "intelligence/asset_list.html"
    paginate_by = 50
    ordering = ["type", "name"]


class IdentityList(ListView):
    model = Identity
    template_name = "intelligence/identity_list.html"
    paginate_by = 50
    ordering = ["type", "display_name", "username"]


class GroupList(ListView):
    model = Group
    template_name = "intelligence/group_list.html"
    paginate_by = 50
    ordering = ["type", "name"]


class EnvironmentList(ListView):
    model = Environment
    template_name = "intelligence/environment_list.html"
    paginate_by = 50
    ordering = ["type", "name"]


class LocationList(ListView):
    model = Location
    template_name = "intelligence/location_list.html"
    paginate_by = 50
    ordering = ["type", "name"]


class BusinessServiceList(ListView):
    model = BusinessService
    template_name = "intelligence/businessservice_list.html"
    paginate_by = 50
    ordering = ["name"]


class TeamList(ListView):
    model = Team
    template_name = "intelligence/team_list.html"
    paginate_by = 50
    ordering = ["name"]


class RelationshipList(ListView):
    model = EntityRelationship
    template_name = "intelligence/relationship_list.html"
    paginate_by = 100
    ordering = ["-updated_at"]


class SyncRunList(ListView):
    model = SyncRun
    template_name = "intelligence/syncrun_list.html"
    paginate_by = 50
    ordering = ["-started_at"]


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
PY

echo "==> Writing urls.py..."
cat > "$APP/urls.py" <<'PY'
from django.urls import path
from . import views

app_name = "intelligence"

urlpatterns = [
    # Assets
    path("assets/", views.AssetList.as_view(), name="asset_list"),
    path("assets/<uuid:pk>/", views.AssetDetail.as_view(), name="asset_detail"),

    # Identities
    path("identities/", views.IdentityList.as_view(), name="identity_list"),
    path("identities/<uuid:pk>/", views.IdentityDetail.as_view(), name="identity_detail"),

    # Groups
    path("groups/", views.GroupList.as_view(), name="group_list"),
    path("groups/<uuid:pk>/", views.GroupDetail.as_view(), name="group_detail"),

    # Environments
    path("environments/", views.EnvironmentList.as_view(), name="environment_list"),
    path("environments/<uuid:pk>/", views.EnvironmentDetail.as_view(), name="environment_detail"),

    # Locations
    path("locations/", views.LocationList.as_view(), name="location_list"),
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

echo "==> Writing connector skeleton..."
cat > "$APP/connectors/base.py" <<'PY'
from __future__ import annotations
from dataclasses import dataclass
from typing import Iterable, Any, Dict, Optional
from django.utils import timezone
from ..models import SyncRun, RawRecord, SourceSystem


@dataclass
class ConnectorConfig:
    source: str
    enabled: bool = True
    priority: int = 100  # lower wins in conflicts


class BaseConnector:
    """
    Extend this for ServiceNow, Flexera, Okta, AD, Duo, etc.
    Pattern:
      - fetch_records() yields raw dicts
      - ingest() stores RawRecord entries
      - normalize() maps into your internal models
    """
    config: ConnectorConfig

    def __init__(self, config: ConnectorConfig):
        self.config = config

    def fetch_records(self) -> Iterable[Dict[str, Any]]:
        raise NotImplementedError

    def record_type(self) -> str:
        return "generic"

    def external_id_from_payload(self, payload: Dict[str, Any]) -> str:
        return payload.get("id") or payload.get("sys_id") or ""

    def ingest(self) -> SyncRun:
        run = SyncRun.objects.create(
            source=self.config.source,
            started_at=timezone.now(),
            success=False,
        )

        try:
            for payload in self.fetch_records():
                RawRecord.objects.create(
                    sync_run=run,
                    source=self.config.source,
                    record_type=self.record_type(),
                    external_id=self.external_id_from_payload(payload),
                    payload=payload,
                    processed=False,
                )

            run.success = True
            run.summary = "Ingest complete."
        except Exception as e:
            run.success = False
            run.error = str(e)
        finally:
            run.finished_at = timezone.now()
            run.save()

        return run
PY

echo "==> Writing templates..."
cat > "$APP/templates/$APP/_list_base.html" <<'HTML'
{% extends "base.html" %}
{% block content %}
<div class="mx-auto max-w-6xl p-6">
  <div class="flex items-center justify-between mb-6">
    <h1 class="text-2xl font-semibold text-slate-900 dark:text-slate-100">
      {{ title }}
    </h1>
  </div>

  <div class="overflow-x-auto bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl shadow-sm">
    <table class="min-w-full divide-y divide-slate-200 dark:divide-slate-700">
      <thead class="bg-slate-50 dark:bg-slate-900/40">
        <tr>
          {% for h in headers %}
            <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-600 dark:text-slate-300">
              {{ h }}
            </th>
          {% endfor %}
        </tr>
      </thead>
      <tbody class="divide-y divide-slate-100 dark:divide-slate-700">
        {% block rows %}{% endblock %}
      </tbody>
    </table>
  </div>

  {% if is_paginated %}
  <div class="mt-6 flex gap-2">
    {% if page_obj.has_previous %}
      <a class="px-3 py-1 rounded bg-slate-200 dark:bg-slate-700" href="?page={{ page_obj.previous_page_number }}">Prev</a>
    {% endif %}
    <span class="px-3 py-1 text-slate-700 dark:text-slate-200">
      Page {{ page_obj.number }} of {{ page_obj.paginator.num_pages }}
    </span>
    {% if page_obj.has_next %}
      <a class="px-3 py-1 rounded bg-slate-200 dark:bg-slate-700" href="?page={{ page_obj.next_page_number }}">Next</a>
    {% endif %}
  </div>
  {% endif %}
</div>
{% endblock %}
HTML

cat > "$APP/templates/$APP/_detail_base.html" <<'HTML'
{% extends "base.html" %}
{% block content %}
<div class="mx-auto max-w-4xl p-6">
  <div class="mb-6">
    <h1 class="text-2xl font-semibold text-slate-900 dark:text-slate-100">{{ object }}</h1>
    <p class="text-sm text-slate-500 dark:text-slate-400 mt-1">{{ subtitle }}</p>
  </div>

  <div class="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl shadow-sm p-5">
    {% block fields %}{% endblock %}
  </div>
</div>
{% endblock %}
HTML

# ---- Asset templates
cat > "$APP/templates/$APP/asset_list.html" <<'HTML'
{% include "intelligence/_list_base.html" with title="Assets" headers="Name,Type,Criticality,Data Class,Owner Team,Environment,Location,State,Updated".split(",") %}
{% block rows %}
  {% for a in object_list %}
  <tr class="hover:bg-slate-50 dark:hover:bg-slate-900/30">
    <td class="px-4 py-2 font-medium">
      <a class="text-indigo-600 dark:text-indigo-400 hover:underline" href="{% url 'intelligence:asset_detail' a.id %}">{{ a.name }}</a>
    </td>
    <td class="px-4 py-2">{{ a.get_type_display }}</td>
    <td class="px-4 py-2">{{ a.get_criticality_display }}</td>
    <td class="px-4 py-2">{{ a.get_data_classification_display }}</td>
    <td class="px-4 py-2">{{ a.owner_team|default:"—" }}</td>
    <td class="px-4 py-2">{{ a.environment|default:"—" }}</td>
    <td class="px-4 py-2">{{ a.location|default:"—" }}</td>
    <td class="px-4 py-2">{{ a.get_lifecycle_state_display }}</td>
    <td class="px-4 py-2 text-sm text-slate-500 dark:text-slate-400">{{ a.updated_at|date:"Y-m-d H:i" }}</td>
  </tr>
  {% empty %}
  <tr><td class="px-4 py-6 text-slate-500 dark:text-slate-400" colspan="9">No assets yet.</td></tr>
  {% endfor %}
{% endblock %}
HTML

cat > "$APP/templates/$APP/asset_detail.html" <<'HTML'
{% include "intelligence/_detail_base.html" with subtitle="Asset detail" %}
{% block fields %}
  <dl class="grid grid-cols-1 md:grid-cols-2 gap-4">
    <div><dt class="font-semibold">Type</dt><dd>{{ object.get_type_display }}</dd></div>
    <div><dt class="font-semibold">Criticality</dt><dd>{{ object.get_criticality_display }}</dd></div>
    <div><dt class="font-semibold">Data Classification</dt><dd>{{ object.get_data_classification_display }}</dd></div>
    <div><dt class="font-semibold">Owner Person</dt><dd>{{ object.owner_person|default:"—" }}</dd></div>
    <div><dt class="font-semibold">Owner Team</dt><dd>{{ object.owner_team|default:"—" }}</dd></div>
    <div><dt class="font-semibold">Business Service</dt><dd>{{ object.business_service|default:"—" }}</dd></div>
    <div><dt class="font-semibold">Environment</dt><dd>{{ object.environment|default:"—" }}</dd></div>
    <div><dt class="font-semibold">Location</dt><dd>{{ object.location|default:"—" }}</dd></div>
    <div><dt class="font-semibold">Lifecycle</dt><dd>{{ object.get_lifecycle_state_display }}</dd></div>
    <div><dt class="font-semibold">First Seen</dt><dd>{{ object.first_seen_at|default:"—" }}</dd></div>
    <div><dt class="font-semibold">Last Seen</dt><dd>{{ object.last_seen_at|default:"—" }}</dd></div>
    <div class="md:col-span-2"><dt class="font-semibold">Description</dt><dd>{{ object.description|default:"—" }}</dd></div>
  </dl>
{% endblock %}
HTML

# ---- Identity templates
cat > "$APP/templates/$APP/identity_list.html" <<'HTML'
{% include "intelligence/_list_base.html" with title="Identities" headers="Name,Username,Email,Type,Status,Owner Team,Last Login,Updated".split(",") %}
{% block rows %}
  {% for i in object_list %}
  <tr class="hover:bg-slate-50 dark:hover:bg-slate-900/30">
    <td class="px-4 py-2 font-medium">
      <a class="text-indigo-600 dark:text-indigo-400 hover:underline" href="{% url 'intelligence:identity_detail' i.id %}">{{ i.display_name|default:i.username|default:i.id }}</a>
    </td>
    <td class="px-4 py-2">{{ i.username|default:"—" }}</td>
    <td class="px-4 py-2">{{ i.email|default:"—" }}</td>
    <td class="px-4 py-2">{{ i.get_type_display }}</td>
    <td class="px-4 py-2">{{ i.get_status_display }}</td>
    <td class="px-4 py-2">{{ i.owner_team|default:"—" }}</td>
    <td class="px-4 py-2">{{ i.last_login_at|default:"—" }}</td>
    <td class="px-4 py-2 text-sm text-slate-500 dark:text-slate-400">{{ i.updated_at|date:"Y-m-d H:i" }}</td>
  </tr>
  {% empty %}
  <tr><td class="px-4 py-6 text-slate-500 dark:text-slate-400" colspan="8">No identities yet.</td></tr>
  {% endfor %}
{% endblock %}
HTML

cat > "$APP/templates/$APP/identity_detail.html" <<'HTML'
{% include "intelligence/_detail_base.html" with subtitle="Identity detail" %}
{% block fields %}
  <dl class="grid grid-cols-1 md:grid-cols-2 gap-4">
    <div><dt class="font-semibold">Username</dt><dd>{{ object.username|default:"—" }}</dd></div>
    <div><dt class="font-semibold">Email</dt><dd>{{ object.email|default:"—" }}</dd></div>
    <div><dt class="font-semibold">Type</dt><dd>{{ object.get_type_display }}</dd></div>
    <div><dt class="font-semibold">Status</dt><dd>{{ object.get_status_display }}</dd></div>
    <div><dt class="font-semibold">Org Unit</dt><dd>{{ object.org_unit|default:"—" }}</dd></div>
    <div><dt class="font-semibold">Manager</dt><dd>{{ object.manager_identity|default:"—" }}</dd></div>
    <div><dt class="font-semibold">Owner Team</dt><dd>{{ object.owner_team|default:"—" }}</dd></div>
    <div><dt class="font-semibold">Last Login</dt><dd>{{ object.last_login_at|default:"—" }}</dd></div>
    <div class="md:col-span-2"><dt class="font-semibold">Risk Flags</dt><dd>{{ object.risk_flags|default:"[]" }}</dd></div>
  </dl>
{% endblock %}
HTML

# ---- Group templates
cat > "$APP/templates/$APP/group_list.html" <<'HTML'
{% include "intelligence/_list_base.html" with title="Groups / Roles" headers="Name,Type,Owner Team,State,Updated".split(",") %}
{% block rows %}
  {% for g in object_list %}
  <tr class="hover:bg-slate-50 dark:hover:bg-slate-900/30">
    <td class="px-4 py-2 font-medium">
      <a class="text-indigo-600 dark:text-indigo-400 hover:underline" href="{% url 'intelligence:group_detail' g.id %}">{{ g.name }}</a>
    </td>
    <td class="px-4 py-2">{{ g.get_type_display }}</td>
    <td class="px-4 py-2">{{ g.owner_team|default:"—" }}</td>
    <td class="px-4 py-2">{{ g.get_lifecycle_state_display }}</td>
    <td class="px-4 py-2 text-sm text-slate-500 dark:text-slate-400">{{ g.updated_at|date:"Y-m-d H:i" }}</td>
  </tr>
  {% empty %}
  <tr><td class="px-4 py-6 text-slate-500 dark:text-slate-400" colspan="5">No groups yet.</td></tr>
  {% endfor %}
{% endblock %}
HTML

cat > "$APP/templates/$APP/group_detail.html" <<'HTML'
{% include "intelligence/_detail_base.html" with subtitle="Group detail" %}
{% block fields %}
  <dl class="grid grid-cols-1 md:grid-cols-2 gap-4">
    <div><dt class="font-semibold">Type</dt><dd>{{ object.get_type_display }}</dd></div>
    <div><dt class="font-semibold">Owner Team</dt><dd>{{ object.owner_team|default:"—" }}</dd></div>
    <div><dt class="font-semibold">Lifecycle</dt><dd>{{ object.get_lifecycle_state_display }}</dd></div>
    <div class="md:col-span-2"><dt class="font-semibold">Description</dt><dd>{{ object.description|default:"—" }}</dd></div>
    <div class="md:col-span-2"><dt class="font-semibold">Members</dt>
      <dd>
        <ul class="list-disc ml-6">
          {% for m in object.members.all %}
            <li><a class="text-indigo-600 dark:text-indigo-400 hover:underline" href="{% url 'intelligence:identity_detail' m.id %}">{{ m }}</a></li>
          {% empty %}
            <li class="text-slate-500 dark:text-slate-400">No members.</li>
          {% endfor %}
        </ul>
      </dd>
    </div>
  </dl>
{% endblock %}
HTML

# ---- Environment templates
cat > "$APP/templates/$APP/environment_list.html" <<'HTML'
{% include "intelligence/_list_base.html" with title="Environments" headers="Name,Type,Region,Network Zone,Owner Team,Criticality,State,Updated".split(",") %}
{% block rows %}
  {% for e in object_list %}
  <tr class="hover:bg-slate-50 dark:hover:bg-slate-900/30">
    <td class="px-4 py-2 font-medium">
      <a class="text-indigo-600 dark:text-indigo-400 hover:underline" href="{% url 'intelligence:environment_detail' e.id %}">{{ e.name }}</a>
    </td>
    <td class="px-4 py-2">{{ e.type }}</td>
    <td class="px-4 py-2">{{ e.region|default:"—" }}</td>
    <td class="px-4 py-2">{{ e.network_zone|default:"—" }}</td>
    <td class="px-4 py-2">{{ e.owner_team|default:"—" }}</td>
    <td class="px-4 py-2">{{ e.get_criticality_display }}</td>
    <td class="px-4 py-2">{{ e.get_lifecycle_state_display }}</td>
    <td class="px-4 py-2 text-sm text-slate-500 dark:text-slate-400">{{ e.updated_at|date:"Y-m-d H:i" }}</td>
  </tr>
  {% empty %}
  <tr><td class="px-4 py-6 text-slate-500 dark:text-slate-400" colspan="8">No environments yet.</td></tr>
  {% endfor %}
{% endblock %}
HTML

cat > "$APP/templates/$APP/environment_detail.html" <<'HTML'
{% include "intelligence/_detail_base.html" with subtitle="Environment detail" %}
{% block fields %}
  <dl class="grid grid-cols-1 md:grid-cols-2 gap-4">
    <div><dt class="font-semibold">Type</dt><dd>{{ object.type }}</dd></div>
    <div><dt class="font-semibold">Region</dt><dd>{{ object.region|default:"—" }}</dd></div>
    <div><dt class="font-semibold">Network Zone</dt><dd>{{ object.network_zone|default:"—" }}</dd></div>
    <div><dt class="font-semibold">Owner Team</dt><dd>{{ object.owner_team|default:"—" }}</dd></div>
    <div><dt class="font-semibold">Criticality</dt><dd>{{ object.get_criticality_display }}</dd></div>
    <div><dt class="font-semibold">Lifecycle</dt><dd>{{ object.get_lifecycle_state_display }}</dd></div>
    <div class="md:col-span-2"><dt class="font-semibold">Description</dt><dd>{{ object.description|default:"—" }}</dd></div>
  </dl>
{% endblock %}
HTML

# ---- Location templates
cat > "$APP/templates/$APP/location_list.html" <<'HTML'
{% include "intelligence/_list_base.html" with title="Locations" headers="Name,Type,City,State/Region,Country,Tier,State,Updated".split(",") %}
{% block rows %}
  {% for l in object_list %}
  <tr class="hover:bg-slate-50 dark:hover:bg-slate-900/30">
    <td class="px-4 py-2 font-medium">
      <a class="text-indigo-600 dark:text-indigo-400 hover:underline" href="{% url 'intelligence:location_detail' l.id %}">{{ l.name }}</a>
    </td>
    <td class="px-4 py-2">{{ l.get_type_display }}</td>
    <td class="px-4 py-2">{{ l.city|default:"—" }}</td>
    <td class="px-4 py-2">{{ l.state_region|default:"—" }}</td>
    <td class="px-4 py-2">{{ l.country|default:"—" }}</td>
    <td class="px-4 py-2">{{ l.get_tier_display }}</td>
    <td class="px-4 py-2">{{ l.get_lifecycle_state_display }}</td>
    <td class="px-4 py-2 text-sm text-slate-500 dark:text-slate-400">{{ l.updated_at|date:"Y-m-d H:i" }}</td>
  </tr>
  {% empty %}
  <tr><td class="px-4 py-6 text-slate-500 dark:text-slate-400" colspan="8">No locations yet.</td></tr>
  {% endfor %}
{% endblock %}
HTML

cat > "$APP/templates/$APP/location_detail.html" <<'HTML'
{% include "intelligence/_detail_base.html" with subtitle="Location detail" %}
{% block fields %}
  <dl class="grid grid-cols-1 md:grid-cols-2 gap-4">
    <div><dt class="font-semibold">Type</dt><dd>{{ object.get_type_display }}</dd></div>
    <div><dt class="font-semibold">Address</dt><dd>{{ object.address|default:"—" }}</dd></div>
    <div><dt class="font-semibold">City</dt><dd>{{ object.city|default:"—" }}</dd></div>
    <div><dt class="font-semibold">State/Region</dt><dd>{{ object.state_region|default:"—" }}</dd></div>
    <div><dt class="font-semibold">Country</dt><dd>{{ object.country|default:"—" }}</dd></div>
    <div><dt class="font-semibold">Tier</dt><dd>{{ object.get_tier_display }}</dd></div>
    <div><dt class="font-semibold">Lifecycle</dt><dd>{{ object.get_lifecycle_state_display }}</dd></div>
    <div class="md:col-span-2"><dt class="font-semibold">Description</dt><dd>{{ object.description|default:"—" }}</dd></div>
  </dl>
{% endblock %}
HTML

# ---- BusinessService templates
cat > "$APP/templates/$APP/businessservice_list.html" <<'HTML'
{% include "intelligence/_list_base.html" with title="Business Services" headers="Name,Owner Team,Criticality,Updated".split(",") %}
{% block rows %}
  {% for b in object_list %}
  <tr class="hover:bg-slate-50 dark:hover:bg-slate-900/30">
    <td class="px-4 py-2 font-medium">
      <a class="text-indigo-600 dark:text-indigo-400 hover:underline" href="{% url 'intelligence:businessservice_detail' b.id %}">{{ b.name }}</a>
    </td>
    <td class="px-4 py-2">{{ b.owner_team|default:"—" }}</td>
    <td class="px-4 py-2">{{ b.get_criticality_display }}</td>
    <td class="px-4 py-2 text-sm text-slate-500 dark:text-slate-400">{{ b.updated_at|date:"Y-m-d H:i" }}</td>
  </tr>
  {% empty %}
  <tr><td class="px-4 py-6 text-slate-500 dark:text-slate-400" colspan="4">No business services yet.</td></tr>
  {% endfor %}
{% endblock %}
HTML

cat > "$APP/templates/$APP/businessservice_detail.html" <<'HTML'
{% include "intelligence/_detail_base.html" with subtitle="Business service detail" %}
{% block fields %}
  <dl class="grid grid-cols-1 md:grid-cols-2 gap-4">
    <div><dt class="font-semibold">Owner Team</dt><dd>{{ object.owner_team|default:"—" }}</dd></div>
    <div><dt class="font-semibold">Criticality</dt><dd>{{ object.get_criticality_display }}</dd></div>
    <div class="md:col-span-2"><dt class="font-semibold">Description</dt><dd>{{ object.description|default:"—" }}</dd></div>
  </dl>
{% endblock %}
HTML

# ---- Team templates
cat > "$APP/templates/$APP/team_list.html" <<'HTML'
{% include "intelligence/_list_base.html" with title="Teams" headers="Name,Parent Team,Criticality,Updated".split(",") %}
{% block rows %}
  {% for t in object_list %}
  <tr class="hover:bg-slate-50 dark:hover:bg-slate-900/30">
    <td class="px-4 py-2 font-medium">
      <a class="text-indigo-600 dark:text-indigo-400 hover:underline" href="{% url 'intelligence:team_detail' t.id %}">{{ t.name }}</a>
    </td>
    <td class="px-4 py-2">{{ t.parent_team|default:"—" }}</td>
    <td class="px-4 py-2">{{ t.get_criticality_display }}</td>
    <td class="px-4 py-2 text-sm text-slate-500 dark:text-slate-400">{{ t.updated_at|date:"Y-m-d H:i" }}</td>
  </tr>
  {% empty %}
  <tr><td class="px-4 py-6 text-slate-500 dark:text-slate-400" colspan="4">No teams yet.</td></tr>
  {% endfor %}
{% endblock %}
HTML

cat > "$APP/templates/$APP/team_detail.html" <<'HTML'
{% include "intelligence/_detail_base.html" with subtitle="Team detail" %}
{% block fields %}
  <dl class="grid grid-cols-1 md:grid-cols-2 gap-4">
    <div><dt class="font-semibold">Parent Team</dt><dd>{{ object.parent_team|default:"—" }}</dd></div>
    <div><dt class="font-semibold">Criticality</dt><dd>{{ object.get_criticality_display }}</dd></div>
    <div class="md:col-span-2"><dt class="font-semibold">Description</dt><dd>{{ object.description|default:"—" }}</dd></div>
  </dl>
{% endblock %}
HTML

# ---- Relationships templates
cat > "$APP/templates/$APP/relationship_list.html" <<'HTML'
{% include "intelligence/_list_base.html" with title="Entity Relationships" headers="From Type,From ID,Relationship,To Type,To ID,Source,Confidence,Updated".split(",") %}
{% block rows %}
  {% for r in object_list %}
  <tr class="hover:bg-slate-50 dark:hover:bg-slate-900/30">
    <td class="px-4 py-2">{{ r.get_from_entity_type_display }}</td>
    <td class="px-4 py-2 font-mono text-xs">{{ r.from_entity_id }}</td>
    <td class="px-4 py-2">{{ r.get_relationship_type_display }}</td>
    <td class="px-4 py-2">{{ r.get_to_entity_type_display }}</td>
    <td class="px-4 py-2 font-mono text-xs">{{ r.to_entity_id }}</td>
    <td class="px-4 py-2">{{ r.get_source_display }}</td>
    <td class="px-4 py-2">{{ r.confidence }}</td>
    <td class="px-4 py-2 text-sm text-slate-500 dark:text-slate-400">{{ r.updated_at|date:"Y-m-d H:i" }}</td>
  </tr>
  {% empty %}
  <tr><td class="px-4 py-6 text-slate-500 dark:text-slate-400" colspan="8">No relationships yet.</td></tr>
  {% endfor %}
{% endblock %}
HTML

# ---- SyncRuns templates
cat > "$APP/templates/$APP/syncrun_list.html" <<'HTML'
{% include "intelligence/_list_base.html" with title="Connector Sync Runs" headers="Source,Started,Finished,Success,Summary".split(",") %}
{% block rows %}
  {% for s in object_list %}
  <tr class="hover:bg-slate-50 dark:hover:bg-slate-900/30">
    <td class="px-4 py-2">{{ s.get_source_display }}</td>
    <td class="px-4 py-2">{{ s.started_at|date:"Y-m-d H:i" }}</td>
    <td class="px-4 py-2">{{ s.finished_at|default:"—" }}</td>
    <td class="px-4 py-2">
      {% if s.success %}
      <span class="inline-flex px-2 py-0.5 rounded bg-green-100 text-green-700 dark:bg-green-900/40 dark:text-green-300">Yes</span>
      {% else %}
      <span class="inline-flex px-2 py-0.5 rounded bg-red-100 text-red-700 dark:bg-red-900/40 dark:text-red-300">No</span>
      {% endif %}
    </td>
    <td class="px-4 py-2 text-sm text-slate-600 dark:text-slate-300">{{ s.summary|default:s.error|default:"—" }}</td>
  </tr>
  {% empty %}
  <tr><td class="px-4 py-6 text-slate-500 dark:text-slate-400" colspan="5">No sync runs yet.</td></tr>
  {% endfor %}
{% endblock %}
HTML

echo "==> Done scaffolding '$APP'."
echo ""
echo "NEXT STEPS:"
echo "1) Add '$APP' to INSTALLED_APPS in your settings.py."
echo "2) Include intelligence URLs in your root urls.py:"
echo "     path('intelligence/', include('intelligence.urls'))"
echo "3) Run migrations:"
echo "     python3 manage.py makemigrations intelligence"
echo "     python3 manage.py migrate"
echo ""
echo "Optional: create superuser and visit /admin/."
PY

chmod +x "$APP"/connectors/base.py

echo "==> Scaffold complete."
