from django import forms
from .models import Asset, Identity, Location

class AssetForm(forms.ModelForm):
    class Meta:
        model = Asset
        fields = "__all__"

class IdentityForm(forms.ModelForm):
    class Meta:
        model = Identity
        fields = "__all__"

class LocationForm(forms.ModelForm):
    class Meta:
        model = Location
        fields = "__all__"
