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
