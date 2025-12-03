"""
SSO Service for Keycloak integration
"""
import requests
from django.conf import settings
from django.contrib.auth import get_user_model
from django.core.cache import cache
from typing import Optional, Dict, Any
from apps.shared.utils.logging import get_logger

User = get_user_model()
logger = get_logger(__name__)


class SSOService:
    """Service for handling SSO operations with Keycloak"""
    
    @staticmethod
    def get_authorization_url(redirect_uri: str, state: Optional[str] = None) -> Dict[str, str]:
        """
        Get Keycloak authorization URL for SSO login
        
        Args:
            redirect_uri: URI to redirect after authentication
            state: Optional state parameter for CSRF protection
            
        Returns:
            Dictionary with authorization_url and state
        """
        try:
            keycloak_url = f"{settings.KEYCLOAK_SERVER_URL}/realms/{settings.KEYCLOAK_REALM}"
            auth_url = f"{keycloak_url}/protocol/openid-connect/auth"
            
            params = {
                'client_id': settings.KEYCLOAK_CLIENT_ID,
                'redirect_uri': redirect_uri,
                'response_type': 'code',
                'scope': 'openid profile email',
                'state': state or SSOService._generate_state(),
            }
            
            # Build query string
            query_string = '&'.join([f"{k}={v}" for k, v in params.items()])
            authorization_url = f"{auth_url}?{query_string}"
            
            # Cache state for validation
            if state is None:
                cache.set(f'sso_state:{params["state"]}', True, 600)  # 10 minutes
            
            return {
                'authorization_url': authorization_url,
                'state': params['state']
            }
        except Exception as e:
            logger.error(f"Error generating authorization URL: {e}")
            raise
    
    @staticmethod
    def exchange_code_for_tokens(authorization_code: str, redirect_uri: str) -> Dict[str, Any]:
        """
        Exchange authorization code for access and ID tokens
        
        Args:
            authorization_code: Authorization code from Keycloak
            redirect_uri: Redirect URI used in authorization
            
        Returns:
            Dictionary with tokens and user info
        """
        try:
            keycloak_url = f"{settings.KEYCLOAK_SERVER_URL}/realms/{settings.KEYCLOAK_REALM}"
            token_url = f"{keycloak_url}/protocol/openid-connect/token"
            
            data = {
                'grant_type': 'authorization_code',
                'client_id': settings.KEYCLOAK_CLIENT_ID,
                'client_secret': settings.KEYCLOAK_CLIENT_SECRET,
                'code': authorization_code,
                'redirect_uri': redirect_uri,
            }
            
            response = requests.post(token_url, data=data)
            response.raise_for_status()
            token_data = response.json()
            
            # Get user info
            user_info = SSOService.get_user_info(token_data['access_token'])
            
            return {
                'access_token': token_data['access_token'],
                'refresh_token': token_data.get('refresh_token'),
                'id_token': token_data.get('id_token'),
                'expires_in': token_data.get('expires_in', 3600),
                'user_info': user_info
            }
        except requests.RequestException as e:
            logger.error(f"Error exchanging code for tokens: {e}")
            raise Exception(f"Failed to exchange authorization code: {str(e)}")
    
    @staticmethod
    def get_user_info(access_token: str) -> Dict[str, Any]:
        """
        Get user information from Keycloak using access token
        
        Args:
            access_token: Keycloak access token
            
        Returns:
            User information dictionary
        """
        try:
            keycloak_url = f"{settings.KEYCLOAK_SERVER_URL}/realms/{settings.KEYCLOAK_REALM}"
            userinfo_url = f"{keycloak_url}/protocol/openid-connect/userinfo"
            
            headers = {'Authorization': f'Bearer {access_token}'}
            response = requests.get(userinfo_url, headers=headers)
            response.raise_for_status()
            
            return response.json()
        except requests.RequestException as e:
            logger.error(f"Error getting user info: {e}")
            raise Exception(f"Failed to get user info: {str(e)}")
    
    @staticmethod
    def refresh_access_token(refresh_token: str) -> Dict[str, Any]:
        """
        Refresh access token using refresh token
        
        Args:
            refresh_token: Keycloak refresh token
            
        Returns:
            New token data
        """
        try:
            keycloak_url = f"{settings.KEYCLOAK_SERVER_URL}/realms/{settings.KEYCLOAK_REALM}"
            token_url = f"{keycloak_url}/protocol/openid-connect/token"
            
            data = {
                'grant_type': 'refresh_token',
                'client_id': settings.KEYCLOAK_CLIENT_ID,
                'client_secret': settings.KEYCLOAK_CLIENT_SECRET,
                'refresh_token': refresh_token,
            }
            
            response = requests.post(token_url, data=data)
            response.raise_for_status()
            
            return response.json()
        except requests.RequestException as e:
            logger.error(f"Error refreshing token: {e}")
            raise Exception(f"Failed to refresh token: {str(e)}")
    
    @staticmethod
    def logout(refresh_token: str) -> bool:
        """
        Logout from Keycloak
        
        Args:
            refresh_token: Keycloak refresh token
            
        Returns:
            True if logout successful
        """
        try:
            keycloak_url = f"{settings.KEYCLOAK_SERVER_URL}/realms/{settings.KEYCLOAK_REALM}"
            logout_url = f"{keycloak_url}/protocol/openid-connect/logout"
            
            data = {
                'client_id': settings.KEYCLOAK_CLIENT_ID,
                'client_secret': settings.KEYCLOAK_CLIENT_SECRET,
                'refresh_token': refresh_token,
            }
            
            response = requests.post(logout_url, data=data)
            response.raise_for_status()
            
            return True
        except requests.RequestException as e:
            logger.error(f"Error logging out: {e}")
            return False
    
    @staticmethod
    def get_or_create_user_from_keycloak(user_info: Dict[str, Any]) -> User:
        """
        Get or create Django user from Keycloak user info
        
        Args:
            user_info: User information from Keycloak
            
        Returns:
            Django User instance
        """
        username = user_info.get('preferred_username') or user_info.get('sub')
        email = user_info.get('email')
        first_name = user_info.get('given_name', '')
        last_name = user_info.get('family_name', '')
        
        if not username:
            raise ValueError('No username found in Keycloak user info')
        
        # Get user type from token (custom claim or default to student)
        user_type = user_info.get('user_type', 'student')
        
        try:
            user = User.objects.get(username=username)
            # Update user info from Keycloak
            if email:
                user.email = email
            if first_name:
                user.first_name = first_name
            if last_name:
                user.last_name = last_name
            user.user_type = user_type
            user.is_active = True
            user.save()
        except User.DoesNotExist:
            user = User.objects.create_user(
                username=username,
                email=email or f"{username}@keycloak.local",
                first_name=first_name,
                last_name=last_name,
                user_type=user_type
            )
            logger.info(f"Created new user from Keycloak: {username}")
        
        return user
    
    @staticmethod
    def validate_state(state: str) -> bool:
        """
        Validate state parameter for CSRF protection
        
        Args:
            state: State parameter to validate
            
        Returns:
            True if state is valid
        """
        cache_key = f'sso_state:{state}'
        is_valid = cache.get(cache_key) is not None
        if is_valid:
            cache.delete(cache_key)  # One-time use
        return is_valid
    
    @staticmethod
    def _generate_state() -> str:
        """Generate a random state string"""
        import secrets
        return secrets.token_urlsafe(32)

















