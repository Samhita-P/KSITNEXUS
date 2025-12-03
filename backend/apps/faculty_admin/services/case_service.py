"""
Case Management Service
"""
from typing import List, Optional, Dict
from django.contrib.auth import get_user_model
from django.db.models import Q, Count, Avg, F
from django.utils import timezone
from datetime import timedelta
from apps.faculty_admin.models import Case, CaseUpdate, CaseTag
from apps.shared.utils.logging import get_logger

User = get_user_model()
logger = get_logger(__name__)


class CaseService:
    """Service for case management"""
    
    @staticmethod
    def calculate_priority_score(case: Case) -> int:
        """Calculate priority score for a case"""
        score = 0
        
        # Base priority
        priority_weights = {
            'low': 1,
            'medium': 3,
            'high': 5,
            'urgent': 8,
            'critical': 10,
        }
        score += priority_weights.get(case.priority, 0)
        
        # Age factor (older cases get higher score)
        age_hours = (timezone.now() - case.created_at).total_seconds() / 3600
        if age_hours > 48:
            score += 2
        elif age_hours > 24:
            score += 1
        
        # SLA risk
        if case.sla_status == 'breached':
            score += 5
        elif case.sla_status == 'at_risk':
            score += 2
        
        # Update frequency (many updates might indicate complexity)
        if case.updates_count > 5:
            score += 1
        
        return min(score, 20)  # Cap at 20
    
    @staticmethod
    def get_case_analytics(user: Optional[User] = None, department: Optional[str] = None):
        """Get case management analytics"""
        queryset = Case.objects.all()
        
        if user:
            queryset = queryset.filter(assigned_to=user)
        if department:
            queryset = queryset.filter(department=department)
        
        total_cases = queryset.count()
        resolved_cases = queryset.filter(status='resolved').count()
        active_cases = queryset.filter(status__in=['new', 'assigned', 'in_progress']).count()
        
        # SLA metrics
        on_time = queryset.filter(sla_status='on_time', status='resolved').count()
        breached = queryset.filter(sla_status='breached').count()
        at_risk = queryset.filter(sla_status='at_risk').count()
        
        # Average resolution time
        resolved = queryset.filter(status='resolved', resolution_time_hours__isnull=False)
        avg_resolution_hours = resolved.aggregate(
            avg=Avg('resolution_time_hours')
        )['avg'] or 0
        
        # By priority
        by_priority = queryset.values('priority').annotate(count=Count('id'))
        
        # By status
        by_status = queryset.values('status').annotate(count=Count('id'))
        
        return {
            'total_cases': total_cases,
            'resolved_cases': resolved_cases,
            'active_cases': active_cases,
            'resolution_rate': (resolved_cases / total_cases * 100) if total_cases > 0 else 0,
            'sla_metrics': {
                'on_time': on_time,
                'at_risk': at_risk,
                'breached': breached,
                'on_time_rate': (on_time / resolved_cases * 100) if resolved_cases > 0 else 0,
            },
            'avg_resolution_hours': avg_resolution_hours,
            'by_priority': list(by_priority),
            'by_status': list(by_status),
        }
    
    @staticmethod
    def get_cases_at_risk():
        """Get cases at risk of SLA breach"""
        return Case.objects.filter(
            sla_status__in=['at_risk', 'breached'],
            status__in=['new', 'assigned', 'in_progress']
        ).order_by('sla_breach_time')
    
    @staticmethod
    def update_case_priority(case: Case):
        """Update case priority score"""
        case.priority_score = CaseService.calculate_priority_score(case)
        case.save(update_fields=['priority_score'])

















