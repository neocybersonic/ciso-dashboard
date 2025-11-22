from django.db import models
from common.models import BaseModel

class Organization(BaseModel):
    name = models.CharField(max_length=200, unique=True)

    def __str__(self):
        return self.name


class FeatureFlag(BaseModel):
    org = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name="feature_flags")
    key = models.CharField(max_length=64)  # e.g., "risks", "controls"
    enabled = models.BooleanField(default=True)

    class Meta:
        unique_together = ("org", "key")

    def __str__(self):
        return f"{self.org}::{self.key}={self.enabled}"
