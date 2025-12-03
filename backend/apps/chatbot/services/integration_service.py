"""
Integration Service for chatbot API integration and action execution
"""
from typing import Dict, List, Optional, Any
from django.contrib.auth import get_user_model
from django.utils import timezone
from apps.chatbot.models import ChatbotSession
from apps.chatbot.models_nlp import ChatbotAction, ChatbotActionExecution
from apps.shared.utils.logging import get_logger

User = get_user_model()
logger = get_logger(__name__)


class IntegrationService:
    """Service for integrating chatbot with external APIs and executing actions"""
    
    @staticmethod
    def execute_action(
        action: ChatbotAction,
        session: ChatbotSession,
        user: Optional[User],
        parameters: Dict[str, Any],
    ) -> Dict[str, Any]:
        """Execute a chatbot action"""
        # Create execution record
        execution = ChatbotActionExecution.objects.create(
            action=action,
            session=session,
            user=user,
            parameters=parameters,
            status='pending',
        )
        
        action.increment_usage()
        
        try:
            import time
            start_time = time.time()
            
            # Execute action based on type
            if action.action_type == 'api_call':
                result = IntegrationService._execute_api_call(action, parameters)
            elif action.action_type == 'database_query':
                result = IntegrationService._execute_database_query(action, parameters)
            elif action.action_type == 'notification':
                result = IntegrationService._execute_notification(action, parameters, user)
            elif action.action_type == 'calendar':
                result = IntegrationService._execute_calendar_action(action, parameters, user)
            elif action.action_type == 'reservation':
                result = IntegrationService._execute_reservation_action(action, parameters, user)
            elif action.action_type == 'study_group':
                result = IntegrationService._execute_study_group_action(action, parameters, user)
            else:
                result = {'success': False, 'error': 'Unknown action type'}
            
            execution_time = time.time() - start_time
            
            # Update execution record
            execution.status = 'success' if result.get('success', False) else 'failed'
            execution.result = result
            execution.execution_time = execution_time
            execution.save()
            
            if execution.status == 'success':
                action.increment_success()
            else:
                action.increment_failure()
                execution.error_message = result.get('error', 'Unknown error')
                execution.save()
            
            return result
            
        except Exception as e:
            logger.error(f"Error executing action {action.name}: {str(e)}", exc_info=True)
            
            execution.status = 'failed'
            execution.error_message = str(e)
            execution.save()
            
            action.increment_failure()
            
            return {
                'success': False,
                'error': str(e),
            }
    
    @staticmethod
    def _execute_api_call(action: ChatbotAction, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Execute API call action"""
        # Placeholder for API call execution
        # In production, this would make actual API calls
        logger.info(f"Executing API call: {action.name} with parameters: {parameters}")
        
        return {
            'success': True,
            'data': {'message': 'API call executed successfully'},
        }
    
    @staticmethod
    def _execute_database_query(action: ChatbotAction, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Execute database query action"""
        # Placeholder for database query execution
        # In production, this would execute actual database queries
        logger.info(f"Executing database query: {action.name} with parameters: {parameters}")
        
        return {
            'success': True,
            'data': {'message': 'Database query executed successfully'},
        }
    
    @staticmethod
    def _execute_notification(action: ChatbotAction, parameters: Dict[str, Any], user: Optional[User]) -> Dict[str, Any]:
        """Execute notification action"""
        if not user:
            return {'success': False, 'error': 'User required for notification action'}
        
        try:
            from apps.notifications.notification_service import NotificationService
            
            title = parameters.get('title', 'Notification')
            message = parameters.get('message', '')
            notification_type = parameters.get('notification_type', 'general')
            priority = parameters.get('priority', 'normal')
            
            NotificationService.create_notification(
                user=user,
                title=title,
                message=message,
                notification_type=notification_type,
                priority=priority,
            )
            
            return {
                'success': True,
                'data': {'message': 'Notification sent successfully'},
            }
        except Exception as e:
            logger.error(f"Error sending notification: {str(e)}", exc_info=True)
            return {
                'success': False,
                'error': str(e),
            }
    
    @staticmethod
    def _execute_calendar_action(action: ChatbotAction, parameters: Dict[str, Any], user: Optional[User]) -> Dict[str, Any]:
        """Execute calendar action"""
        if not user:
            return {'success': False, 'error': 'User required for calendar action'}
        
        try:
            from apps.calendars.services import CalendarService
            
            action_name = action.name.lower()
            
            if 'create' in action_name or 'add' in action_name:
                # Create calendar event
                event = CalendarService.create_event(
                    user=user,
                    title=parameters.get('title', 'Event'),
                    description=parameters.get('description'),
                    start_time=parameters.get('start_time'),
                    end_time=parameters.get('end_time'),
                    event_type=parameters.get('event_type', 'event'),
                    location=parameters.get('location'),
                )
                
                return {
                    'success': True,
                    'data': {'event_id': event.id, 'message': 'Event created successfully'},
                }
            elif 'list' in action_name or 'get' in action_name:
                # List calendar events
                events = CalendarService.get_events(user=user)
                
                return {
                    'success': True,
                    'data': {'events': [{'id': e.id, 'title': e.title} for e in events[:10]]},
                }
            else:
                return {'success': False, 'error': 'Unknown calendar action'}
                
        except Exception as e:
            logger.error(f"Error executing calendar action: {str(e)}", exc_info=True)
            return {
                'success': False,
                'error': str(e),
            }
    
    @staticmethod
    def _execute_reservation_action(action: ChatbotAction, parameters: Dict[str, Any], user: Optional[User]) -> Dict[str, Any]:
        """Execute reservation action"""
        if not user:
            return {'success': False, 'error': 'User required for reservation action'}
        
        try:
            # Placeholder for reservation action
            # In production, this would interact with reservation system
            logger.info(f"Executing reservation action: {action.name} with parameters: {parameters}")
            
            return {
                'success': True,
                'data': {'message': 'Reservation action executed successfully'},
            }
        except Exception as e:
            logger.error(f"Error executing reservation action: {str(e)}", exc_info=True)
            return {
                'success': False,
                'error': str(e),
            }
    
    @staticmethod
    def _execute_study_group_action(action: ChatbotAction, parameters: Dict[str, Any], user: Optional[User]) -> Dict[str, Any]:
        """Execute study group action"""
        if not user:
            return {'success': False, 'error': 'User required for study group action'}
        
        try:
            # Placeholder for study group action
            # In production, this would interact with study group system
            logger.info(f"Executing study group action: {action.name} with parameters: {parameters}")
            
            return {
                'success': True,
                'data': {'message': 'Study group action executed successfully'},
            }
        except Exception as e:
            logger.error(f"Error executing study group action: {str(e)}", exc_info=True)
            return {
                'success': False,
                'error': str(e),
            }
    
    @staticmethod
    def get_available_actions(user: Optional[User] = None) -> List[ChatbotAction]:
        """Get available actions for a user"""
        actions = ChatbotAction.objects.filter(is_active=True)
        
        # Filter by user permissions if user is provided
        if user:
            # Could add permission-based filtering here
            pass
        
        return list(actions)
    
    @staticmethod
    def find_action_by_intent(intent: str, user: Optional[User] = None) -> Optional[ChatbotAction]:
        """Find action by intent"""
        # Map intents to actions
        intent_action_map = {
            'calendar': 'calendar',
            'reservation': 'reservation',
            'study_group': 'study_group',
            'notification': 'notification',
        }
        
        action_type = intent_action_map.get(intent)
        if not action_type:
            return None
        
        actions = ChatbotAction.objects.filter(
            action_type=action_type,
            is_active=True,
        ).order_by('-usage_count', '-success_count')[:1]
        
        return actions[0] if actions else None

