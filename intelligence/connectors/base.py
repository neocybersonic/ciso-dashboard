from __future__ import annotations
from dataclasses import dataclass
from typing import Iterable, Any, Dict, Optional
from django.utils import timezone
from ..models import SyncRun, RawRecord, SourceSystem


@dataclass
class ConnectorConfig:
    source: str
    enabled: bool = True
    priority: int = 100  # lower wins in conflicts


class BaseConnector:
    """
    Extend this for ServiceNow, Flexera, Okta, AD, Duo, etc.
    Pattern:
      - fetch_records() yields raw dicts
      - ingest() stores RawRecord entries
      - normalize() maps into your internal models
    """
    config: ConnectorConfig

    def __init__(self, config: ConnectorConfig):
        self.config = config

    def fetch_records(self) -> Iterable[Dict[str, Any]]:
        raise NotImplementedError

    def record_type(self) -> str:
        return "generic"

    def external_id_from_payload(self, payload: Dict[str, Any]) -> str:
        return payload.get("id") or payload.get("sys_id") or ""

    def ingest(self) -> SyncRun:
        run = SyncRun.objects.create(
            source=self.config.source,
            started_at=timezone.now(),
            success=False,
        )

        try:
            for payload in self.fetch_records():
                RawRecord.objects.create(
                    sync_run=run,
                    source=self.config.source,
                    record_type=self.record_type(),
                    external_id=self.external_id_from_payload(payload),
                    payload=payload,
                    processed=False,
                )

            run.success = True
            run.summary = "Ingest complete."
        except Exception as e:
            run.success = False
            run.error = str(e)
        finally:
            run.finished_at = timezone.now()
            run.save()

        return run
