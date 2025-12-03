"""
Serializers for complaints app
"""
from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import Complaint, ComplaintAttachment, ComplaintUpdate

User = get_user_model()


class ComplaintAttachmentSerializer(serializers.ModelSerializer):
    """Complaint attachment serializer"""
    file_url = serializers.SerializerMethodField()
    file_type = serializers.SerializerMethodField()
    
    class Meta:
        model = ComplaintAttachment
        fields = ['id', 'file', 'file_url', 'file_name', 'file_type', 'file_size', 'uploaded_at']
        read_only_fields = ['id', 'file_size', 'uploaded_at', 'file_url', 'file_type']
    
    def get_file_url(self, obj):
        if obj.file:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.file.url)
            return obj.file.url
        return None
    
    def get_file_type(self, obj):
        if obj.file_name:
            extension = obj.file_name.split('.')[-1].lower()
            if extension in ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp']:
                return 'image'
            elif extension in ['pdf', 'doc', 'docx', 'txt', 'rtf']:
                return 'document'
            elif extension in ['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm']:
                return 'video'
            elif extension in ['mp3', 'wav', 'aac', 'flac', 'ogg']:
                return 'audio'
        return 'file'


class ComplaintUpdateSerializer(serializers.ModelSerializer):
    """Complaint update serializer"""
    updated_by = serializers.StringRelatedField(read_only=True, allow_null=True)
    updated_at = serializers.SerializerMethodField()
    
    class Meta:
        model = ComplaintUpdate
        fields = ['id', 'updated_by', 'status', 'comment', 'is_internal', 'created_at', 'updated_at']
        read_only_fields = ['id', 'updated_by', 'created_at', 'updated_at']
    
    def get_updated_at(self, obj):
        return obj.created_at.isoformat()


class ComplaintSerializer(serializers.ModelSerializer):
    """Complaint serializer"""
    attachments = ComplaintAttachmentSerializer(many=True, read_only=True)
    updates = ComplaintUpdateSerializer(many=True, read_only=True)
    assigned_to = serializers.StringRelatedField(read_only=True, allow_null=True)
    assigned_to_name = serializers.SerializerMethodField()
    
    class Meta:
        model = Complaint
        fields = [
            'id', 'complaint_id', 'category', 'title', 'description', 'urgency',
            'status', 'contact_email', 'contact_phone', 'location', 'assigned_to',
            'assigned_to_name', 'submitted_at', 'updated_at', 'resolved_at', 'priority_score',
            'attachments', 'updates'
        ]
        read_only_fields = [
            'id', 'complaint_id', 'submitted_at', 'updated_at', 'resolved_at',
            'priority_score', 'attachments', 'updates', 'assigned_to_name'
        ]
    
    def get_assigned_to_name(self, obj):
        return obj.assigned_to.get_full_name() if obj.assigned_to else None


class ComplaintCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating complaints"""
    attachments = serializers.ListField(
        child=serializers.FileField(),
        required=False,
        write_only=True,
        allow_empty=True
    )
    
    class Meta:
        model = Complaint
        fields = [
            'id', 'complaint_id', 'category', 'title', 'description', 'urgency', 
            'status', 'contact_email', 'contact_phone', 'location', 'submitted_at', 
            'updated_at', 'assigned_to', 'attachments'
        ]
        read_only_fields = [
            'id', 'complaint_id', 'status', 'submitted_at', 'updated_at', 
            'assigned_to', 'attachments'
        ]
    
    def create(self, validated_data):
        attachments_data = validated_data.pop('attachments', [])
        
        # Ensure all required fields have default values
        validated_data.setdefault('contact_email', None)
        validated_data.setdefault('contact_phone', None)
        validated_data.setdefault('location', None)
        
        complaint = Complaint.objects.create(**validated_data)
        
        # Create attachments
        for attachment_file in attachments_data:
            if attachment_file:  # Check if file is not None
                ComplaintAttachment.objects.create(
                    complaint=complaint,
                    file=attachment_file,
                    file_name=attachment_file.name,
                    file_size=attachment_file.size
                )
        
        # Refresh the complaint to get all fields
        complaint.refresh_from_db()
        return complaint


class ComplaintUpdateStatusSerializer(serializers.ModelSerializer):
    """Serializer for updating complaint status"""
    comment = serializers.CharField(required=False, allow_blank=True)
    is_internal = serializers.BooleanField(default=False)
    
    class Meta:
        model = Complaint
        fields = ['status', 'comment', 'is_internal', 'internal_notes']
    
    def update(self, instance, validated_data):
        comment = validated_data.pop('comment', '')
        is_internal = validated_data.pop('is_internal', False)
        internal_notes = validated_data.pop('internal_notes', '')
        
        # Update complaint
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        
        # Create status update
        if comment:
            ComplaintUpdate.objects.create(
                complaint=instance,
                updated_by=self.context['request'].user,
                status=instance.status,
                comment=comment,
                is_internal=is_internal
            )
        
        # Update internal notes
        if internal_notes:
            instance.internal_notes = internal_notes
            instance.save()
        
        return instance


class ComplaintListSerializer(serializers.ModelSerializer):
    """Simplified complaint serializer for list views"""
    assigned_to = serializers.StringRelatedField(read_only=True, allow_null=True)
    assigned_to_name = serializers.SerializerMethodField()
    attachments = ComplaintAttachmentSerializer(many=True, read_only=True)
    updates = ComplaintUpdateSerializer(many=True, read_only=True)
    
    class Meta:
        model = Complaint
        fields = [
            'id', 'complaint_id', 'category', 'title', 'description', 'urgency', 'status',
            'contact_email', 'contact_phone', 'location', 'submitted_at', 'updated_at',
            'assigned_to', 'assigned_to_name', 'attachments', 'updates'
        ]
    
    def get_assigned_to_name(self, obj):
        return obj.assigned_to.get_full_name() if obj.assigned_to else None


class ComplaintResponseSerializer(serializers.Serializer):
    """Serializer for faculty response to complaints"""
    message = serializers.CharField(max_length=1000, help_text="Response message to the student")
    attachments = serializers.ListField(
        child=serializers.FileField(),
        required=False,
        allow_empty=True,
        help_text="Optional file attachments for the response"
    )


class MarkResolvedSerializer(serializers.Serializer):
    """Serializer for marking complaints as resolved"""
    comment = serializers.CharField(
        max_length=500, 
        required=False, 
        allow_blank=True,
        help_text="Optional comment explaining the resolution"
    )
