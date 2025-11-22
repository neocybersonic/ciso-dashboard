from django.urls import path
from . import views
from .create_views import RiskCreate

app_name = "risks"

urlpatterns = [
    path("", views.RiskList.as_view(), name="list"),
    path("add/", RiskCreate.as_view(), name="add"),
]
