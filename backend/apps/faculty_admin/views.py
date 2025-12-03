"""
Views for faculty_admin app
"""
from rest_framework import generics, status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from django.db.models import Q, Count
from django.utils import timezone
from .models import (
    Case, CaseTag, CaseUpdate, Broadcast, BroadcastEngagement,
    PredictiveMetric, OperationalAlert
)
from .serializers import (
    CaseSerializer, CaseTagSerializer, CaseUpdateSerializer,
    BroadcastSerializer, BroadcastEngagementSerializer,
    PredictiveMetricSerializer, OperationalAlertSerializer
)
from .services.case_service import CaseService
from .services.broadcast_service import BroadcastService
from .services.predictive_service import PredictiveService
from apps.shared.utils.logging import get_logger

User = get_user_model()
logger = get_logger(__name__)


# Case Management
class CaseListView(generics.ListCreateAPIView):
    """List and create cases"""
    serializer_class = CaseSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        queryset = Case.objects.all().select_related('assigned_to', 'created_by')
        
        if user.user_type == 'student':
            queryset = queryset.filter(created_by=user)
        elif user.user_type in ['faculty', 'admin']:
            if self.request.query_params.get('my_cases') == 'true':
                queryset = queryset.filter(assigned_to=user)
        
        status_filter = self.request.query_params.get('status')
        priority_filter = self.request.query_params.get('priority')
        
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        if priority_filter:
            queryset = queryset.filter(priority=priority_filter)
        
        return queryset.order_by('-created_at')
    
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)


class CaseDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Case detail view"""
    queryset = Case.objects.all()
    serializer_class = CaseSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        instance.views_count += 1
        instance.save(update_fields=['views_count'])
        serializer = self.get_serializer(instance)
        return Response(serializer.data)


class CaseUpdateListView(generics.ListCreateAPIView):
    """List and create case updates"""
    serializer_class = CaseUpdateSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        case_id = self.request.query_params.get('case_id')
        if case_id:
            return CaseUpdate.objects.filter(case_id=case_id).select_related('updated_by')
        return CaseUpdate.objects.none()
    
    def perform_create(self, serializer):
        case = serializer.validated_data['case']
        case.updates_count += 1
        case.save(update_fields=['updates_count'])
        serializer.save(updated_by=self.request.user)


# Broadcast Studio
class BroadcastListView(generics.ListCreateAPIView):
    """List and create broadcasts"""
    serializer_class = BroadcastSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        from django.db.models import Q
        from django.utils import timezone
        
        queryset = Broadcast.objects.all().select_related('created_by')
        
        # If my_broadcasts is true, show all broadcasts created by the user (drafts and published)
        if self.request.query_params.get('my_broadcasts') == 'true':
            queryset = queryset.filter(created_by=user)
        else:
            # Otherwise, show only published broadcasts that are relevant to the user
            now = timezone.now()
            queryset = queryset.filter(
                Q(is_published=True) &
                # Check if broadcast is scheduled (if scheduled_at exists, it should be in the past or null)
                (Q(scheduled_at__isnull=True) | Q(scheduled_at__lte=now)) &
                # Check if broadcast hasn't expired (if expires_at exists, it should be in the future or null)
                (Q(expires_at__isnull=True) | Q(expires_at__gt=now))
            )
            
            # Filter by target audience based on user type
            if user.user_type == 'student':
                queryset = queryset.filter(
                    Q(target_audience='all') | 
                    Q(target_audience='students') |
                    (Q(target_audience='specific') & Q(target_users=user))
                )
            elif user.user_type == 'faculty':
                queryset = queryset.filter(
                    Q(target_audience='all') | 
                    Q(target_audience='faculty') |
                    (Q(target_audience='specific') & Q(target_users=user))
                )
            elif user.user_type == 'staff':
                queryset = queryset.filter(
                    Q(target_audience='all') | 
                    Q(target_audience='staff') |
                    (Q(target_audience='specific') & Q(target_users=user))
                )
            # Admin can see all broadcasts
        
        broadcast_type = self.request.query_params.get('type')
        if broadcast_type:
            queryset = queryset.filter(broadcast_type=broadcast_type)
        
        return queryset.order_by('-created_at').distinct()
    
    def create(self, request, *args, **kwargs):
        # Only faculty and admin can create broadcasts
        if request.user.user_type not in ['faculty', 'admin']:
            return Response(
                {'error': 'Only faculty and admin can create broadcasts.'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        try:
            # Extract ManyToMany field before validation (create a copy to avoid mutating request.data)
            data = request.data.copy() if hasattr(request.data, 'copy') else dict(request.data)
            target_user_ids = data.pop('target_users', []) if 'target_users' in data else []
            
            serializer = self.get_serializer(data=data)
            serializer.is_valid(raise_exception=True)
            
            # Create the broadcast with the user
            broadcast = serializer.save(created_by=request.user)
            
            # Handle ManyToMany field (target_users) if provided
            if target_user_ids and isinstance(target_user_ids, list) and target_user_ids:
                from django.contrib.auth import get_user_model
                User = get_user_model()
                try:
                    # Convert to integers if they're strings
                    user_ids = [int(uid) for uid in target_user_ids if uid]
                    target_users = User.objects.filter(id__in=user_ids)
                    broadcast.target_users.set(target_users)
                except (ValueError, TypeError) as e:
                    print(f"Warning: Invalid target user IDs: {e}")
            
            # Refresh from database to get computed fields
            broadcast.refresh_from_db()
            
            # Serialize the response
            response_serializer = self.get_serializer(broadcast)
            headers = self.get_success_headers(response_serializer.data)
            return Response(response_serializer.data, status=status.HTTP_201_CREATED, headers=headers)
        except Exception as e:
            print(f"Error creating broadcast: {e}")
            import traceback
            traceback.print_exc()
            return Response(
                {'error': f'Failed to create broadcast: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class BroadcastDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Broadcast detail view"""
    queryset = Broadcast.objects.all()
    serializer_class = BroadcastSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        if request.user.is_authenticated:
            BroadcastService.track_view(instance, request.user)
        serializer = self.get_serializer(instance)
        return Response(serializer.data)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def publish_broadcast(request, broadcast_id):
    """Publish a broadcast"""
    try:
        broadcast = Broadcast.objects.get(id=broadcast_id, created_by=request.user)
        BroadcastService.publish_broadcast(broadcast)
        serializer = BroadcastSerializer(broadcast)
        return Response(serializer.data)
    except Broadcast.DoesNotExist:
        return Response(
            {'error': 'Broadcast not found'},
            status=status.HTTP_404_NOT_FOUND
        )


# Predictive Operations
@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def case_analytics(request):
    """Get case management analytics"""
    department = request.query_params.get('department')
    analytics = CaseService.get_case_analytics(request.user, department)
    return Response(analytics)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def predictive_metrics(request):
    """Get predictive metrics - always calculate fresh metrics from real data"""
    metric_type = request.query_params.get('metric_type')
    
    # Always calculate fresh metrics from real data
    try:
        PredictiveService.calculate_metrics()
    except Exception as e:
        logger.error(f"Error calculating metrics: {e}")
        # Continue to return existing metrics if calculation fails
    
    queryset = PredictiveMetric.objects.all()
    
    if metric_type and metric_type != 'all':
        queryset = queryset.filter(metric_type=metric_type)
    
    # Get the latest metrics for each type
    if metric_type == 'all' or not metric_type:
        # Get latest metric for each type
        latest_metrics = []
        for metric_type_val in ['complaint_volume', 'response_time', 'resolution_rate', 'sla_breach', 
                               'engagement', 'resource_utilization']:
            latest = queryset.filter(metric_type=metric_type_val).order_by('-period_end').first()
            if latest:
                latest_metrics.append(latest)
        queryset = PredictiveMetric.objects.filter(id__in=[m.id for m in latest_metrics])
    
    serializer = PredictiveMetricSerializer(queryset.order_by('-period_end')[:10], many=True)
    return Response(serializer.data)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def operational_alerts(request):
    """Get operational alerts - always generate fresh alerts from real data"""
    severity = request.query_params.get('severity')
    is_acknowledged = request.query_params.get('is_acknowledged')
    
    # Always generate fresh alerts from real-time data
    try:
        PredictiveService.generate_operational_alerts()
    except Exception as e:
        logger.error(f"Error generating operational alerts: {e}")
        # Continue to return existing alerts if generation fails
    
    queryset = OperationalAlert.objects.filter(is_resolved=False)
    
    if severity:
        queryset = queryset.filter(severity=severity)
    if is_acknowledged is not None:
        queryset = queryset.filter(is_acknowledged=is_acknowledged.lower() == 'true')
    
    serializer = OperationalAlertSerializer(queryset.order_by('-created_at'), many=True)
    return Response(serializer.data)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def acknowledge_alert(request, alert_id):
    """Acknowledge an operational alert"""
    try:
        alert = OperationalAlert.objects.get(id=alert_id)
        alert.is_acknowledged = True
        alert.acknowledged_by = request.user
        alert.acknowledged_at = timezone.now()
        alert.save()
        
        serializer = OperationalAlertSerializer(alert)
        return Response(serializer.data)
    except OperationalAlert.DoesNotExist:
        return Response(
            {'error': 'Alert not found'},
            status=status.HTTP_404_NOT_FOUND
        )


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated, permissions.IsAdminUser])
def generate_alerts(request):
    """Manually trigger operational alerts generation (admin only)"""
    try:
        alerts = PredictiveService.generate_operational_alerts()
        serializer = OperationalAlertSerializer(alerts, many=True)
        return Response({
            'message': f'Generated {len(alerts)} alerts',
            'alerts': serializer.data
        })
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def cases_at_risk(request):
    """Get cases at risk of SLA breach"""
    cases = CaseService.get_cases_at_risk()
    serializer = CaseSerializer(cases, many=True)
    return Response(serializer.data)





