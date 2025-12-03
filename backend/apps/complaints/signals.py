"""
Signals for complaints app
"""
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.contrib.auth import get_user_model
from .models import Complaint
from apps.faculty_admin.models import Case

User = get_user_model()


@receiver(post_save, sender=Complaint)
def create_case_from_complaint(sender, instance, created, **kwargs):
    """
    Automatically create or update a Case when a Complaint is assigned to a faculty member.
    This ensures cases are available in Case Management for faculty to track.
    """
    # Only create/update case if complaint is assigned to a faculty member
    if instance.assigned_to and instance.assigned_to.user_type == 'faculty':
        # Map complaint urgency to case priority
        urgency_to_priority = {
            'low': 'low',
            'medium': 'medium',
            'high': 'high',
            'urgent': 'critical',
        }
        
        # Map complaint status to case status
        status_mapping = {
            'submitted': 'new',
            'under_review': 'assigned',
            'in_progress': 'in_progress',
            'resolved': 'resolved',
            'rejected': 'closed',
            'closed': 'closed',
        }
        
        # Check if case already exists for this complaint
        case_id = f"COMP-{instance.complaint_id}"
        existing_case = Case.objects.filter(case_id=case_id).first()
        
        if not existing_case:
            # Create new case from complaint
            case = Case.objects.create(
                case_id=case_id,
                case_type='complaint',
                title=instance.title,
                description=instance.description,
                assigned_to=instance.assigned_to,
                created_by=instance.assigned_to,  # Faculty member who will handle it
                status=status_mapping.get(instance.status, 'new'),
                priority=urgency_to_priority.get(instance.urgency, 'medium'),
                category=instance.category,
                sla_target_hours=48,  # Default SLA
            )
            
            # Create initial case update from complaint
            from apps.faculty_admin.models import CaseUpdate
            CaseUpdate.objects.create(
                case=case,
                updated_by=None,  # System-generated
                comment=f"Case created from complaint {instance.complaint_id}: {instance.title}",
                is_internal=False,
            )
        else:
            # Update existing case to sync with complaint
            existing_case.status = status_mapping.get(instance.status, existing_case.status)
            existing_case.assigned_to = instance.assigned_to
            existing_case.title = instance.title
            existing_case.description = instance.description
            existing_case.priority = urgency_to_priority.get(instance.urgency, existing_case.priority)
            existing_case.save()

