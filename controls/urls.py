from django.urls import path
from . import views
from .create_views import ControlCreate

app_name = "controls"

urlpatterns = [
    path("", views.ControlList.as_view(), name="list"),
    path("add/", ControlCreate.as_view(), name="add"),
]
