from django.db import models
from core.models import Organization

class Control(models.Model):
    STATUS = [
        ("Effective", "Effective"),
        ("Needs Improvement", "Needs Improvement"),
        ("Failing", "Failing"),
    ]

    org = models.ForeignKey(
        Organization,
        null=True,
        blank=True,
        on_delete=models.CASCADE,
        related_name="controls"
    )
    short_description = models.CharField(max_length=200)
    long_description = models.TextField(blank=True)
    owner = models.CharField(max_length=200, blank=True)
    status = models.CharField(max_length=20, choices=STATUS, default="Effective")

    class Meta:
        unique_together = ("org", "short_description")
        indexes = [models.Index(fields=["status"])]

    def __str__(self):
        if self.org:
            return f"[{self.org.name}] {self.short_description}"
        return self.short_description
