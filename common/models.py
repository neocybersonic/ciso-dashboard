from django.db import models

# Create your models here.
from django.db import models
import uuid

class BaseModel(models.Model):
    """Abstract base with UUID PK and timestamps. No domain knowledge."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True
