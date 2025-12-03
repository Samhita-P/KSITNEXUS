"""
Predictive Operations Service
"""
from typing import List, Dict, Optional
from django.contrib.auth import get_user_model
from django.db.models import Count, Avg, Q
from django.utils import timezone
from datetime import timedelta
from apps.faculty_admin.models import Case, PredictiveMetric, OperationalAlert
from apps.shared.utils.logging import get_logger

User = get_user_model()
logger = get_logger(__name__)


class PredictiveService:
    """Service for predictive analytics and operations"""
    
    @staticmethod
    def predict_complaint_volume(days_ahead: int = 7) -> Dict:
        """Predict complaint volume for next N days"""
        # Simple moving average prediction (can be enhanced with ML)
        end_date = timezone.now()
        start_date = end_date - timedelta(days=30)
        
        # Get historical data
        cases = Case.objects.filter(
            created_at__gte=start_date,
            created_at__lte=end_date
        )
        
        daily_counts = {}
        for case in cases:
            date_key = case.created_at.date()
            daily_counts[date_key] = daily_counts.get(date_key, 0) + 1
        
        # Calculate average
        if daily_counts:
            avg_daily = sum(daily_counts.values()) / len(daily_counts)
        else:
            avg_daily = 0
        
        # Predict future
        predicted_volume = avg_daily * days_ahead
        
        return {
            'current_avg_daily': avg_daily,
            'predicted_volume': predicted_volume,
            'days_ahead': days_ahead,
            'confidence': 0.7,  # Placeholder
        }
    
    @staticmethod
    def predict_sla_breaches() -> List[Case]:
        """Predict cases likely to breach SLA"""
        now = timezone.now()
        risk_threshold = now + timedelta(hours=4)  # 4 hours before breach
        
        return Case.objects.filter(
            sla_breach_time__lte=risk_threshold,
            sla_breach_time__gte=now,
            status__in=['new', 'assigned', 'in_progress']
        ).order_by('sla_breach_time')
    
    @staticmethod
    def generate_operational_alerts():
        """Generate operational alerts based on predictions and send notifications"""
        alerts = []
        
        # Check for SLA risks
        at_risk_cases = PredictiveService.predict_sla_breaches()
        for case in at_risk_cases:
            alert, created = OperationalAlert.objects.get_or_create(
                alert_type='sla_risk',
                related_case=case,
                is_resolved=False,
                defaults={
                    'severity': 'critical' if case.sla_breach_time <= timezone.now() + timedelta(hours=1) else 'warning',
                    'title': f'SLA Risk: {case.case_id}',
                    'message': f'Case {case.case_id} is at risk of SLA breach. Breach time: {case.sla_breach_time}',
                }
            )
            if created:
                alerts.append(alert)
                # Send notification to assigned faculty or all faculty if not assigned
                PredictiveService._notify_alert(alert, case.assigned_to if case.assigned_to else None)
        
        # Check for high volume
        recent_cases = Case.objects.filter(
            created_at__gte=timezone.now() - timedelta(hours=24)
        ).count()
        
        if recent_cases > 20:  # Threshold
            alert, created = OperationalAlert.objects.get_or_create(
                alert_type='high_volume',
                is_resolved=False,
                defaults={
                    'severity': 'warning',
                    'title': 'High Case Volume',
                    'message': f'High number of cases in last 24 hours: {recent_cases} cases. This is {((recent_cases - 15) / 15 * 100):.0f}% above the average.',
                }
            )
            if created:
                alerts.append(alert)
                # Send notification to all faculty members
                PredictiveService._notify_alert(alert, None)
        
        return alerts
    
    @staticmethod
    def _notify_alert(alert: OperationalAlert, target_user: Optional[User] = None):
        """Send notification for an operational alert"""
        try:
            from apps.notifications.notification_service import NotificationService
            
            # Determine priority based on severity
            priority_map = {
                'critical': 'high',
                'warning': 'medium',
                'info': 'low',
            }
            priority = priority_map.get(alert.severity, 'medium')
            
            # If target_user is specified, send to that user
            if target_user:
                NotificationService.create_notification(
                    user=target_user,
                    notification_type='operational_alert',
                    title=alert.title,
                    message=alert.message,
                    priority=priority,
                    data={
                        'alert_id': alert.id,
                        'alert_type': alert.alert_type,
                        'severity': alert.severity,
                        'related_case_id': alert.related_case.id if alert.related_case else None,
                    },
                    related_object_type='operational_alert',
                    related_object_id=alert.id,
                )
            else:
                # Send to all faculty members
                faculty_users = User.objects.filter(
                    groups__name='Faculty',
                    is_active=True
                ).distinct()
                
                for user in faculty_users:
                    NotificationService.create_notification(
                        user=user,
                        notification_type='operational_alert',
                        title=alert.title,
                        message=alert.message,
                        priority=priority,
                        data={
                            'alert_id': alert.id,
                            'alert_type': alert.alert_type,
                            'severity': alert.severity,
                            'related_case_id': alert.related_case.id if alert.related_case else None,
                        },
                        related_object_type='operational_alert',
                        related_object_id=alert.id,
                    )
            
            logger.info(f"Sent notifications for operational alert: {alert.id}")
        except Exception as e:
            logger.error(f"Error sending notification for alert {alert.id}: {e}")
    
    @staticmethod
    def calculate_metrics():
        """Calculate and store all predictive metrics from real data"""
        now = timezone.now()
        period_start = now - timedelta(days=7)
        period_end = now
        metrics = []
        
        # 1. Complaint Volume
        volume = Case.objects.filter(
            created_at__gte=period_start,
            created_at__lte=period_end
        ).count()
        prediction = PredictiveService.predict_complaint_volume(7)
        
        metric, _ = PredictiveMetric.objects.update_or_create(
            metric_type='complaint_volume',
            period_start=period_start,
            period_end=period_end,
            defaults={
                'value': float(volume),
                'predicted_value': prediction['predicted_volume'],
                'confidence': prediction['confidence'],
                'metadata': {
                    'current_avg_daily': prediction['current_avg_daily'],
                    'days_ahead': prediction['days_ahead'],
                }
            }
        )
        metrics.append(metric)
        
        # 2. Response Time (average time from case creation to first update)
        cases_with_updates = Case.objects.filter(
            created_at__gte=period_start,
            created_at__lte=period_end,
            updates__isnull=False
        ).distinct()
        
        response_times = []
        for case in cases_with_updates:
            first_update = case.updates.order_by('created_at').first()
            if first_update:
                response_time = (first_update.created_at - case.created_at).total_seconds() / 3600  # hours
                response_times.append(response_time)
        
        avg_response_time = sum(response_times) / len(response_times) if response_times else 0
        predicted_response = avg_response_time * 1.15 if avg_response_time > 0 else 0  # Predict 15% increase
        
        metric, _ = PredictiveMetric.objects.update_or_create(
            metric_type='response_time',
            period_start=period_start,
            period_end=period_end,
            defaults={
                'value': avg_response_time,
                'predicted_value': predicted_response,
                'confidence': 0.75 if response_times else 0.5,
                'metadata': {
                    'sample_size': len(response_times),
                    'unit': 'hours',
                }
            }
        )
        metrics.append(metric)
        
        # 3. Resolution Rate (percentage of cases resolved)
        total_cases = Case.objects.filter(
            created_at__gte=period_start,
            created_at__lte=period_end
        ).count()
        resolved_cases = Case.objects.filter(
            created_at__gte=period_start,
            created_at__lte=period_end,
            status__in=['resolved', 'closed']
        ).count()
        
        resolution_rate = (resolved_cases / total_cases * 100) if total_cases > 0 else 0
        predicted_resolution = resolution_rate * 0.98 if resolution_rate > 0 else 0  # Predict slight decrease
        
        metric, _ = PredictiveMetric.objects.update_or_create(
            metric_type='resolution_rate',
            period_start=period_start,
            period_end=period_end,
            defaults={
                'value': resolution_rate,
                'predicted_value': predicted_resolution,
                'confidence': 0.80 if total_cases > 0 else 0.5,
                'metadata': {
                    'total_cases': total_cases,
                    'resolved_cases': resolved_cases,
                }
            }
        )
        metrics.append(metric)
        
        # 4. SLA Breach (number of cases that breached SLA)
        breached_cases = Case.objects.filter(
            created_at__gte=period_start,
            created_at__lte=period_end,
            sla_status='breached'
        ).count()
        
        at_risk_cases = Case.objects.filter(
            sla_status='at_risk',
            status__in=['new', 'assigned', 'in_progress']
        ).count()
        predicted_breaches = breached_cases + (at_risk_cases * 0.5)  # Estimate 50% of at-risk will breach
        
        metric, _ = PredictiveMetric.objects.update_or_create(
            metric_type='sla_breach',
            period_start=period_start,
            period_end=period_end,
            defaults={
                'value': float(breached_cases),
                'predicted_value': predicted_breaches,
                'confidence': 0.70,
                'metadata': {
                    'breached_cases': breached_cases,
                    'at_risk_cases': at_risk_cases,
                }
            }
        )
        metrics.append(metric)
        
        # 5. Engagement (from broadcast engagement)
        try:
            from apps.faculty_admin.models import Broadcast
            broadcasts = Broadcast.objects.filter(
                created_at__gte=period_start,
                created_at__lte=period_end
            )
            
            total_views = sum(b.views_count for b in broadcasts)
            total_engagements = sum(b.engagement_count for b in broadcasts)
            
            engagement_rate = (total_engagements / total_views * 100) if total_views > 0 else 0
            predicted_engagement = engagement_rate * 0.95 if engagement_rate > 0 else 0  # Predict slight decrease
            
            metric, _ = PredictiveMetric.objects.update_or_create(
                metric_type='engagement',
                period_start=period_start,
                period_end=period_end,
                defaults={
                    'value': engagement_rate,
                    'predicted_value': predicted_engagement,
                    'confidence': 0.75 if total_views > 0 else 0.5,
                    'metadata': {
                        'total_views': total_views,
                        'total_engagements': total_engagements,
                        'broadcasts_count': broadcasts.count(),
                    }
                }
            )
            metrics.append(metric)
        except Exception as e:
            logger.warning(f"Could not calculate engagement: {e}")
        
        # 7. Resource Utilization (faculty workload - cases per faculty)
        try:
            active_faculty = User.objects.filter(
                groups__name='Faculty',
                is_active=True
            ).count()
            
            active_cases = Case.objects.filter(
                status__in=['new', 'assigned', 'in_progress']
            ).count()
            
            cases_per_faculty = active_cases / active_faculty if active_faculty > 0 else 0
            utilization_rate = min(cases_per_faculty / 10 * 100, 100) if active_faculty > 0 else 0  # Normalize to 10 cases per faculty = 100%
            predicted_utilization = utilization_rate * 1.05 if utilization_rate > 0 else 0  # Predict 5% increase
            
            metric, _ = PredictiveMetric.objects.update_or_create(
                metric_type='resource_utilization',
                period_start=period_start,
                period_end=period_end,
                defaults={
                    'value': utilization_rate,
                    'predicted_value': predicted_utilization,
                    'confidence': 0.72 if active_faculty > 0 else 0.5,
                    'metadata': {
                        'active_faculty': active_faculty,
                        'active_cases': active_cases,
                        'cases_per_faculty': cases_per_faculty,
                    }
                }
            )
            metrics.append(metric)
        except Exception as e:
            logger.warning(f"Could not calculate resource_utilization: {e}")
        
        logger.info(f"Calculated {len(metrics)} predictive metrics")
        return metrics






