from django.shortcuts import render

# Create your views here.
from django.views.generic import ListView
from .models import Control

class ControlList(ListView):
    model = Control
    template_name = "controls/control_list.html"
    context_object_name = "controls"
    paginate_by = 25  # optional
