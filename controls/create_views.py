from django.urls import reverse_lazy
from django.views.generic import CreateView
from .models import Control
from .forms import ControlForm

class ControlCreate(CreateView):
    model = Control
    form_class = ControlForm
    template_name = "controls/control_form.html"
    success_url = reverse_lazy("controls:list")
