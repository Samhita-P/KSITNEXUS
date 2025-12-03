"""
Download view for study group resources
"""
from django.http import HttpResponse, Http404
from django.shortcuts import get_object_or_404
from rest_framework.decorators import api_view, permission_classes
from rest_framework import permissions
from rest_framework.response import Response
from rest_framework import status
import os
import mimetypes
from .models import Resource


@api_view(['GET'])
@permission_classes([permissions.AllowAny])  # Allow anonymous access for now
def download_resource(request, group_id, resource_id):
    """Download a study group resource with proper MIME type"""
    try:
        # Get the resource
        resource = get_object_or_404(Resource, id=resource_id, group_id=group_id)
        
        if not resource.file:
            raise Http404("File not found")
        
        # Get the file path
        file_path = resource.file.path
        
        # Check if file exists
        if not os.path.exists(file_path):
            raise Http404("File not found on server")
        
        # Get MIME type from file extension
        mime_type, _ = mimetypes.guess_type(file_path)
        if not mime_type:
            mime_type = 'application/octet-stream'
        
        # Read file content
        with open(file_path, 'rb') as f:
            file_content = f.read()
        
        # Increment download count
        resource.download_count += 1
        resource.save(update_fields=['download_count'])
        
        # Create response with proper headers
        response = HttpResponse(file_content, content_type=mime_type)
        response['Content-Disposition'] = f'attachment; filename="{resource.file.name.split("/")[-1]}"'
        response['Content-Length'] = len(file_content)
        
        return response
        
    except Http404:
        raise
    except Exception as e:
        return Response(
            {'error': str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
