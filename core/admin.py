from django.contrib import admin
from .models import Organization, FeatureFlag

@admin.register(Organization)
class OrganizationAdmin(admin.ModelAdmin):
    list_display = ("name", "created_at")
    search_fields = ("name",)

@admin.register(FeatureFlag)
class FeatureFlagAdmin(admin.ModelAdmin):
    list_display = ("org", "key", "enabled", "created_at")
    list_filter = ("key", "enabled")
    search_fields = ("org__name", "key")
