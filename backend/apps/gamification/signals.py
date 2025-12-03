"""
Signals for gamification
"""
from django.db.models.signals import post_save, post_delete
from django.db import OperationalError
from django.dispatch import receiver
from django.contrib.auth import get_user_model
from .models import UserPoints, UserStreak, UserAchievement, Achievement
from .services.gamification_service import GamificationService

User = get_user_model()


@receiver(post_save, sender=User)
def create_user_gamification_profile(sender, instance, created, **kwargs):
    """Create gamification profile when user is created"""
    if created:
        try:
            UserPoints.objects.get_or_create(user=instance)
            UserStreak.objects.get_or_create(user=instance)
            
            # Initialize achievements
            GamificationService.initialize_user_achievements(instance)
        except OperationalError as e:
            # Table doesn't exist yet - migrations not run
            # This is OK, gamification features will work after migrations
            print(f"Warning: Gamification tables not found. Run migrations to enable gamification features.")
            print(f"Error: {e}")
        except Exception as e:
            # Any other error - log but don't break user creation
            print(f"Warning: Failed to create gamification profile for user {instance.username}: {e}")


@receiver(post_save, sender=User)
def update_login_streak(sender, instance, **kwargs):
    """Update login streak (called after login)"""
    try:
        streak = instance.streak
        streak.update_streak()
    except UserStreak.DoesNotExist:
        try:
            UserStreak.objects.create(user=instance)
        except OperationalError:
            # Table doesn't exist - skip streak update
            pass
    except OperationalError:
        # Table doesn't exist - skip streak update
        pass
    except Exception as e:
        # Any other error - log but don't break
        print(f"Warning: Failed to update login streak for user {instance.username}: {e}")


