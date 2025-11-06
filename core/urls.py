
# core/urls.py
from django.urls import path
from . import views

urlpatterns = [
    path("", views.home, name="home"),   # landing page for your app
]
