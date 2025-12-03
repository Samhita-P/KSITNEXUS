"""
Celery tasks for faculty admin operations
"""
from celery import shared_task
from apps.faculty_admin.services.predictive_service import PredictiveService
from apps.shared.utils.logging import get_logger

logger = get_logger(__name__)


@shared_task(bind=True, max_retries=3)
def generate_operational_alerts_task(self):
    """
    Periodic task to generate operational alerts.
    This task should run every 15 minutes via Celery Beat.
    """
    try:
        logger.info("Starting operational alerts generation task")
        alerts = PredictiveService.generate_operational_alerts()
        logger.info(f"Generated {len(alerts)} operational alerts")
        return {
            'status': 'success',
            'alerts_generated': len(alerts),
            'alert_ids': [alert.id for alert in alerts]
        }
    except Exception as e:
        logger.error(f"Error in generate_operational_alerts_task: {e}")
        # Retry the task if it fails
        raise self.retry(exc=e, countdown=60)  # Retry after 60 seconds


@shared_task(bind=True, max_retries=3)
def calculate_predictive_metrics_task(self):
    """
    Periodic task to calculate predictive metrics from real data.
    This task should run every hour via Celery Beat.
    """
    try:
        logger.info("Starting predictive metrics calculation task")
        metrics = PredictiveService.calculate_metrics()
        logger.info(f"Calculated {len(metrics)} predictive metrics")
        return {
            'status': 'success',
            'metrics_calculated': len(metrics),
            'metric_ids': [metric.id for metric in metrics]
        }
    except Exception as e:
        logger.error(f"Error in calculate_predictive_metrics_task: {e}")
        # Retry the task if it fails
        raise self.retry(exc=e, countdown=300)  # Retry after 5 minutes

