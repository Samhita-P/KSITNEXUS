"""
Serializers for study_groups app
"""
import json
from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.utils import timezone
from .models import StudyGroup, GroupMembership, GroupMessage, Resource, UpcomingEvent, GroupJoinRequest

User = get_user_model()


class GroupMembershipSerializer(serializers.ModelSerializer):
    """Group membership serializer"""
    user = serializers.StringRelatedField(read_only=True)
    user_id = serializers.ReadOnlyField(source='user.id')
    user_name = serializers.SerializerMethodField()
    user_email = serializers.SerializerMethodField()
    
    class Meta:
        model = GroupMembership
        fields = ['id', 'user', 'user_id', 'user_name', 'user_email', 'role', 'is_active', 'joined_at']
        read_only_fields = ['id', 'joined_at']
    
    def get_user_name(self, obj):
        """Return user's full name"""
        if obj.user:
            if obj.user.first_name and obj.user.last_name:
                return f"{obj.user.first_name} {obj.user.last_name}"
            elif obj.user.first_name:
                return obj.user.first_name
            elif obj.user.email:
                return obj.user.email.split('@')[0]
        return str(obj.user) if obj.user else None
    
    def get_user_email(self, obj):
        """Return user's email"""
        return obj.user.email if obj.user else None


class GroupMessageSerializer(serializers.ModelSerializer):
    """Group message serializer"""
    sender = serializers.SerializerMethodField()
    sender_id = serializers.ReadOnlyField(source='sender.id')
    
    class Meta:
        model = GroupMessage
        fields = [
            'id', 'sender', 'sender_id', 'message_type', 'content', 'attachment',
            'attachment_name', 'is_edited', 'edited_at', 'reply_to',
            'created_at'
        ]
        read_only_fields = ['id', 'sender_id', 'is_edited', 'edited_at', 'created_at']
    
    def get_sender(self, obj):
        """Return a user-friendly sender name"""
        try:
            # Ensure sender is loaded from database
            if not hasattr(obj, 'sender') or not obj.sender:
                print(f"Message {obj.id if hasattr(obj, 'id') else 'unknown'}: No sender found")
                return "Unknown User"
            
            sender = obj.sender
            
            # Debug: Print sender information
            print(f"Message {obj.id if hasattr(obj, 'id') else 'unknown'}: Sender ID={sender.id}, "
                  f"first_name='{sender.first_name}', last_name='{sender.last_name}', "
                  f"email='{sender.email}', username='{getattr(sender, 'username', 'N/A')}'")
            
            # Return first name + last name if available
            if sender.first_name and sender.last_name:
                name = f"{sender.first_name} {sender.last_name}".strip()
                if name:
                    print(f"Returning full name: {name}")
                    return name
            elif sender.first_name:
                name = sender.first_name.strip()
                if name:
                    print(f"Returning first name: {name}")
                    return name
            elif sender.last_name:
                name = sender.last_name.strip()
                if name:
                    print(f"Returning last name: {name}")
                    return name
            
            # Try username if available (AbstractUser should always have this as it's required)
            # Check username first as it's more reliable than email
            if hasattr(sender, 'username') and sender.username:
                username = str(sender.username).strip()
                if username:
                    print(f"Returning username: {username}")
                    return username
            
            # Try email if no name or username available
            if sender.email:
                email = sender.email.strip()
                if email and email != 'anonymous@ksit.com':
                    # Return email username part (before @) if no name available
                    email_username = email.split('@')[0]
                    print(f"Returning email username: {email_username}")
                    return email_username
            
            # Last resort: use user ID
            if hasattr(sender, 'id'):
                user_id_name = f"User {sender.id}"
                print(f"Returning user ID: {user_id_name}")
                return user_id_name
            
            # If we get here, something is wrong
            print(f"ERROR: Could not determine sender name for message {obj.id if hasattr(obj, 'id') else 'unknown'}")
            return "Unknown User"
        except Exception as e:
            # Log error and return fallback
            import traceback
            print(f"ERROR getting sender name for message {obj.id if hasattr(obj, 'id') else 'unknown'}: {e}")
            traceback.print_exc()
            return "Unknown User"


class ResourceSerializer(serializers.ModelSerializer):
    """Resource serializer"""
    uploaded_by = serializers.SerializerMethodField()
    uploaded_by_id = serializers.IntegerField(source='uploaded_by.id', read_only=True)
    file_url = serializers.SerializerMethodField()
    file_name = serializers.SerializerMethodField()
    group_id = serializers.IntegerField(source='group.id', read_only=True)
    
    class Meta:
        model = Resource
        fields = [
            'id', 'group_id', 'uploaded_by_id', 'title', 'description', 'resource_type', 'category', 'file',
            'file_url', 'file_name', 'external_url', 'file_size', 
            'download_count', 'is_pinned', 'uploaded_at', 'uploaded_by'
        ]
        read_only_fields = [
            'id', 'group_id', 'uploaded_by_id', 'file_size', 'download_count', 'uploaded_at', 'uploaded_by'
        ]
    
    def get_uploaded_by(self, obj):
        """Return a user-friendly uploader name"""
        if obj.uploaded_by:
            if obj.uploaded_by.first_name and obj.uploaded_by.last_name:
                return f"{obj.uploaded_by.first_name} {obj.uploaded_by.last_name}"
            elif obj.uploaded_by.first_name:
                return obj.uploaded_by.first_name
            elif obj.uploaded_by.email:
                return obj.uploaded_by.email
            else:
                return "Unknown User"
        return "Anonymous User"
    
    def get_file_url(self, obj):
        """Return the file URL if available"""
        if obj.file:
            return obj.file.url
        return obj.external_url
    
    def get_file_name(self, obj):
        """Return the file name"""
        if obj.file:
            return obj.file.name.split('/')[-1]  # Get just the filename
        return obj.title


class UpcomingEventSerializer(serializers.ModelSerializer):
    """Upcoming event serializer"""
    created_by = serializers.SerializerMethodField()
    
    class Meta:
        model = UpcomingEvent
        fields = [
            'id', 'title', 'description', 'event_type', 'start_time',
            'end_time', 'location', 'meeting_link', 'max_attendees',
            'is_recurring', 'recurring_pattern', 'created_at', 'updated_at', 'created_by'
        ]
        read_only_fields = ['id', 'created_at', 'created_by']
    
    def get_created_by(self, obj):
        """Return a user-friendly creator name"""
        if obj.created_by:
            if obj.created_by.first_name and obj.created_by.last_name:
                return f"{obj.created_by.first_name} {obj.created_by.last_name}"
            elif obj.created_by.first_name:
                return obj.created_by.first_name
            elif obj.created_by.email:
                return obj.created_by.email
            else:
                return "Unknown User"
        return "Anonymous User"


class StudyGroupSerializer(serializers.ModelSerializer):
    """Study group serializer"""
    creator = serializers.SerializerMethodField()
    creator_name = serializers.SerializerMethodField()
    members = GroupMembershipSerializer(many=True, read_only=True)
    current_member_count = serializers.ReadOnlyField()
    is_full = serializers.ReadOnlyField()
    is_member = serializers.SerializerMethodField()
    join_status = serializers.SerializerMethodField()
    
    class Meta:
        model = StudyGroup
        fields = [
            'id', 'name', 'description', 'subject', 'difficulty_level',
            'max_members', 'is_public', 'is_active', 'creator', 'creator_name', 'tags',
            'meeting_schedule', 'meeting_location', 'created_at', 'updated_at',
            'members', 'current_member_count', 'is_full', 'is_member', 'join_status',
            'is_reported', 'reported_by', 'reported_at', 'report_reason', 'status'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'current_member_count', 'is_full']
    
    def get_creator(self, obj):
        """Return creator ID"""
        return obj.creator.id if obj.creator else None
    
    def get_creator_name(self, obj):
        """Return creator's full name"""
        if obj.creator:
            if obj.creator.first_name and obj.creator.last_name:
                return f"{obj.creator.first_name} {obj.creator.last_name}"
            elif obj.creator.first_name:
                return obj.creator.first_name
            elif obj.creator.email:
                return obj.creator.email
        return "Unknown User"
    
    def get_is_member(self, obj):
        """Check if current user is a member"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return GroupMembership.objects.filter(
                group=obj, 
                user=request.user, 
                is_active=True
            ).exists()
        elif request and not request.user.is_authenticated:
            # For anonymous users, check if they're using the anonymous user
            from django.contrib.auth import get_user_model
            User = get_user_model()
            try:
                anonymous_user = User.objects.get(email='anonymous@ksit.com')
                return GroupMembership.objects.filter(
                    group=obj, 
                    user=anonymous_user, 
                    is_active=True
                ).exists()
            except User.DoesNotExist:
                return False
        return False
    
    def get_join_status(self, obj):
        """Get join request status for current user"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            try:
                join_request = GroupJoinRequest.objects.get(
                    group=obj, 
                    user=request.user
                )
                return join_request.status
            except GroupJoinRequest.DoesNotExist:
                return None
        return None


class StudyGroupCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating study groups"""
    
    class Meta:
        model = StudyGroup
        fields = [
            'name', 'description', 'subject', 'difficulty_level',
            'max_members', 'is_public', 'tags', 'meeting_schedule',
            'meeting_location'
        ]
    
    def create(self, validated_data):
        validated_data['creator'] = self.context['request'].user
        group = StudyGroup.objects.create(**validated_data)
        
        # Add creator as admin
        GroupMembership.objects.create(
            group=group,
            user=self.context['request'].user,
            role='admin'
        )
        
        return group


class StudyGroupListSerializer(serializers.ModelSerializer):
    """Simplified study group serializer for list views"""
    creator_name = serializers.SerializerMethodField()
    current_member_count = serializers.ReadOnlyField()
    member_count = serializers.SerializerMethodField()
    level = serializers.SerializerMethodField()
    visibility = serializers.SerializerMethodField()
    members = serializers.SerializerMethodField()
    tags = serializers.SerializerMethodField()
    is_member = serializers.SerializerMethodField()
    
    class Meta:
        model = StudyGroup
        fields = [
            'id', 'name', 'description', 'subject', 'difficulty_level',
            'max_members', 'is_public', 'creator_name', 'created_at',
            'current_member_count', 'is_reported', 'reported_by', 'reported_at', 
            'report_reason', 'status', 'member_count', 'level', 'visibility',
            'members', 'tags', 'is_member'
        ]
    
    def get_creator_name(self, obj):
        """Return creator's full name"""
        if obj.creator:
            if obj.creator.first_name and obj.creator.last_name:
                return f"{obj.creator.first_name} {obj.creator.last_name}"
            elif obj.creator.first_name:
                return obj.creator.first_name
            elif obj.creator.email:
                return obj.creator.email
        return "Unknown"
    
    def get_member_count(self, obj):
        return obj.current_member_count
    
    def get_level(self, obj):
        return obj.difficulty_level
    
    def get_visibility(self, obj):
        return 'public' if obj.is_public else 'private'
    
    def get_members(self, obj):
        """Return active members only"""
        memberships = obj.members.filter(is_active=True)
        return [{
            'id': m.id,
            'user_id': m.user.id if m.user else None,
            'user_name': self._get_user_name(m.user) if m.user else None,
            'user_email': m.user.email if m.user else None,
            'role': m.role,
            'is_active': m.is_active,
            'joined_at': m.joined_at.isoformat() if m.joined_at else None,
        } for m in memberships]
    
    def _get_user_name(self, user):
        """Helper method to get user name"""
        if user.first_name and user.last_name:
            return f"{user.first_name} {user.last_name}"
        elif user.first_name:
            return user.first_name
        elif user.email:
            return user.email.split('@')[0]
        return str(user)
    
    def get_tags(self, obj):
        """Return tags as a list"""
        try:
            if not obj.tags:
                return []
            
            # Tags are stored as JSON, parse them
            if isinstance(obj.tags, list):
                return obj.tags
            elif isinstance(obj.tags, str):
                return json.loads(obj.tags) if obj.tags else []
            else:
                return []
        except (json.JSONDecodeError, AttributeError, TypeError):
            return []
    
    def get_is_member(self, obj):
        """Check if current user is a member"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return GroupMembership.objects.filter(
                group=obj, 
                user=request.user, 
                is_active=True
            ).exists()
        return False


class JoinGroupSerializer(serializers.Serializer):
    """Serializer for joining a group"""
    message = serializers.CharField(required=False, allow_blank=True)


class LeaveGroupSerializer(serializers.Serializer):
    """Serializer for leaving a group"""
    reason = serializers.CharField(required=False, allow_blank=True)


class GroupMessageCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating group messages"""
    
    class Meta:
        model = GroupMessage
        fields = ['message_type', 'content', 'attachment', 'reply_to']
    
    def validate(self, data):
        print(f"Validating data: {data}")
        return data
    
    def create(self, validated_data):
        print(f"Creating message with data: {validated_data}")
        # Get sender from context (set in perform_create)
        validated_data['sender'] = self.context.get('sender')
        validated_data['group'] = self.context.get('group')
        
        if validated_data.get('attachment'):
            validated_data['attachment_name'] = validated_data['attachment'].name
            validated_data['file_size'] = validated_data['attachment'].size
        
        return GroupMessage.objects.create(**validated_data)


class ResourceCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating resources"""
    
    class Meta:
        model = Resource
        fields = ['title', 'description', 'resource_type', 'category', 'file', 'external_url']
    
    def create(self, validated_data):
        validated_data['uploaded_by'] = self.context.get('uploaded_by')
        validated_data['group'] = self.context.get('group')
        
        if validated_data.get('file'):
            validated_data['file_size'] = validated_data['file'].size
        
        return Resource.objects.create(**validated_data)


class EventCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating events"""
    
    class Meta:
        model = UpcomingEvent
        fields = [
            'title', 'description', 'event_type', 'start_time', 'end_time',
            'location', 'meeting_link', 'max_attendees', 'is_recurring',
            'recurring_pattern'
        ]
    
    def create(self, validated_data):
        validated_data['created_by'] = self.context.get('created_by')
        validated_data['group'] = self.context.get('group')
        return UpcomingEvent.objects.create(**validated_data)


class GroupJoinRequestSerializer(serializers.ModelSerializer):
    """Group join request serializer"""
    user = serializers.SerializerMethodField()
    reviewed_by = serializers.SerializerMethodField()
    
    class Meta:
        model = GroupJoinRequest
        fields = [
            'id', 'user', 'status', 'message', 'requested_at', 
            'reviewed_at', 'reviewed_by'
        ]
        read_only_fields = ['id', 'requested_at', 'reviewed_at', 'reviewed_by']
    
    def get_user(self, obj):
        """Return user-friendly name"""
        if obj.user:
            if obj.user.first_name and obj.user.last_name:
                return f"{obj.user.first_name} {obj.user.last_name}"
            elif obj.user.first_name:
                return obj.user.first_name
            elif obj.user.email:
                return obj.user.email
            else:
                return "Unknown User"
        return "Anonymous User"
    
    def get_reviewed_by(self, obj):
        """Return reviewer name"""
        if obj.reviewed_by:
            if obj.reviewed_by.first_name and obj.reviewed_by.last_name:
                return f"{obj.reviewed_by.first_name} {obj.reviewed_by.last_name}"
            elif obj.reviewed_by.first_name:
                return obj.reviewed_by.first_name
            elif obj.reviewed_by.email:
                return obj.reviewed_by.email
            else:
                return "Unknown User"
        return None


class GroupJoinRequestCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating join requests"""
    
    class Meta:
        model = GroupJoinRequest
        fields = ['message']
    
    def create(self, validated_data):
        validated_data['user'] = self.context.get('user')
        validated_data['group'] = self.context.get('group')
        return GroupJoinRequest.objects.create(**validated_data)


class GroupJoinRequestUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating join request status"""
    
    class Meta:
        model = GroupJoinRequest
        fields = ['status']
    
    def update(self, instance, validated_data):
        instance.status = validated_data.get('status', instance.status)
        instance.reviewed_at = timezone.now()
        instance.reviewed_by = self.context.get('reviewer')
        instance.save()
        
        # If approved, create membership
        if instance.status == 'approved':
            GroupMembership.objects.get_or_create(
                group=instance.group,
                user=instance.user,
                defaults={'role': 'member', 'is_active': True}
            )
        
        return instance
