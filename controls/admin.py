from django.contrib import admin
from .models import Control

@admin.register(Control)
class ControlAdmin(admin.ModelAdmin):
    list_display = ("short_description", "long_description", "owner", "status")
    search_fields = ("short_description", "long_description", "owner")
