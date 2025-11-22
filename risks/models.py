from django.db import models
from core.models import Organization

class Risk(models.Model):

    org = models.ForeignKey(
    Organization,
    null=True,
    blank=True,
    on_delete=models.CASCADE,
    related_name="risks",
)

    short_description = models.CharField(max_length=200)
    long_description = models.TextField(blank=True)
    controls = models.ManyToManyField("controls.Control", related_name="risks", blank=True)

    class Meta:
        unique_together = ("org", "short_description")

    def __str__(self):
        return f"[{self.org.name}] {self.short_description}"
