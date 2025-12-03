"""
Simple health check views for Render deployment
"""
from django.http import JsonResponse
from django.views.decorators.http import require_http_methods
from django.views.decorators.csrf import csrf_exempt


@csrf_exempt
@require_http_methods(["GET", "POST"])
def health(request):
    """
    Simple health check endpoint
    Returns 200 OK if server is running
    """
    return JsonResponse({
        "status": "ok",
        "message": "KSIT Nexus API is running",
        "service": "backend"
    })


