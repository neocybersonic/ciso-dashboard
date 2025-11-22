from django.urls import reverse_lazy
from django.views.generic import CreateView
from .models import Risk
from .forms import RiskForm

class RiskCreate(CreateView):
    model = Risk
    form_class = RiskForm
    template_name = "risks/risk_form.html"
    success_url = reverse_lazy("risks:list")
