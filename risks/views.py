from django.shortcuts import render

# Create your views here.
from django.views.generic import ListView
from .models import Risk

class RiskList(ListView):
    model = Risk
    template_name = "risks/risk_list.html"
    context_object_name = "risks"
    paginate_by = 25  # optional
