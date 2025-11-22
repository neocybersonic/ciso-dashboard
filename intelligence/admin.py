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
