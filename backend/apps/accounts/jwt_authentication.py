"""
Custom JWT Authentication with Cookie Support
"""
from django.conf import settings
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework_simplejwt.exceptions import InvalidToken, TokenError
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.settings import api_settings
from django.contrib.auth import get_user_model

User = get_user_model()


class CookieJWTAuthentication(JWTAuthentication):
    """
    Custom JWT Authentication that supports both Authorization header and cookies
    """
    
    def authenticate(self, request):
        # First try to get token from Authorization header
        header = self.get_header(request)
        if header is not None:
            raw_token = self.get_raw_token(header)
            if raw_token is not None:
                validated_token = self.get_validated_token(raw_token)
                return self.get_user(validated_token), validated_token
        
        # If no header token, try to get from cookies
        raw_token = request.COOKIES.get('access_token')
        if raw_token is not None:
            try:
                validated_token = self.get_validated_token(raw_token)
                return self.get_user(validated_token), validated_token
            except TokenError:
                pass
        
        return None


def set_jwt_cookies(response, user):
    """
    Set JWT tokens as httpOnly cookies
    """
    refresh = RefreshToken.for_user(user)
    access_token = refresh.access_token
    
    # Set access token cookie
    response.set_cookie(
        'access_token',
        str(access_token),
        max_age=api_settings.ACCESS_TOKEN_LIFETIME.total_seconds(),
        httponly=True,
        secure=not settings.DEBUG,  # Only secure in production
        samesite='Lax'
    )
    
    # Set refresh token cookie
    response.set_cookie(
        'refresh_token',
        str(refresh),
        max_age=api_settings.REFRESH_TOKEN_LIFETIME.total_seconds(),
        httponly=True,
        secure=not settings.DEBUG,  # Only secure in production
        samesite='Lax'
    )
    
    return response


def clear_jwt_cookies(response):
    """
    Clear JWT cookies
    """
    response.delete_cookie('access_token')
    response.delete_cookie('refresh_token')
    return response


def get_tokens_for_user(user):
    """
    Generate JWT tokens for a user
    """
    refresh = RefreshToken.for_user(user)
    return {
        'access': str(refresh.access_token),
        'refresh': str(refresh),
    }
