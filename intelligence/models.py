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
