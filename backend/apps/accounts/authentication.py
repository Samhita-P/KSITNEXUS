"""
Keycloak authentication for KSIT Nexus
"""
import jwt
import requests
from django.conf import settings
from django.contrib.auth import get_user_model
from rest_framework import authentication, exceptions
from rest_framework.authentication import BaseAuthentication

User = get_user_model()


class KeycloakAuthentication(BaseAuthentication):
    """
    Custom authentication class for Keycloak JWT tokens
    """
    
    def authenticate(self, request):
        auth_header = request.META.get('HTTP_AUTHORIZATION')
        
        if not auth_header or not auth_header.startswith('Bearer '):
            return None
        
        token = auth_header.split(' ')[1]
        
        try:
            # Verify token with Keycloak
            user_info = self.verify_keycloak_token(token)
            
            if not user_info:
                return None
            
            # Get or create user
            user = self.get_or_create_user(user_info)
            
            return (user, token)
            
        except Exception as e:
            raise exceptions.AuthenticationFailed(f'Invalid token: {str(e)}')
    
    def verify_keycloak_token(self, token):
        """
        Verify JWT token with Keycloak
        """
        try:
            # Get Keycloak public key
            keycloak_url = f"{settings.KEYCLOAK_SERVER_URL}/realms/{settings.KEYCLOAK_REALM}"
            jwks_url = f"{keycloak_url}/protocol/openid-connect/certs"
            
            response = requests.get(jwks_url)
            jwks = response.json()
            
            # Decode token header to get key ID
            header = jwt.get_unverified_header(token)
            kid = header.get('kid')
            
            # Find the correct key
            key = None
            for jwk in jwks.get('keys', []):
                if jwk.get('kid') == kid:
                    key = jwt.algorithms.RSAAlgorithm.from_jwk(jwk)
                    break
            
            if not key:
                return None
            
            # Verify and decode token
            payload = jwt.decode(
                token,
                key,
                algorithms=['RS256'],
                audience=settings.KEYCLOAK_CLIENT_ID,
                issuer=f"{keycloak_url}/protocol/openid-connect"
            )
            
            return payload
            
        except Exception as e:
            print(f"Token verification error: {e}")
            return None
    
    def get_or_create_user(self, user_info):
        """
        Get or create user from Keycloak user info
        """
        username = user_info.get('preferred_username')
        email = user_info.get('email')
        first_name = user_info.get('given_name', '')
        last_name = user_info.get('family_name', '')
        
        if not username:
            raise exceptions.AuthenticationFailed('No username in token')
        
        # Get user type from token (custom claim)
        user_type = user_info.get('user_type', 'student')
        
        try:
            user = User.objects.get(username=username)
            # Update user info
            user.email = email
            user.first_name = first_name
            user.last_name = last_name
            user.user_type = user_type
            user.save()
        except User.DoesNotExist:
            user = User.objects.create_user(
                username=username,
                email=email,
                first_name=first_name,
                last_name=last_name,
                user_type=user_type
            )
        
        return user
