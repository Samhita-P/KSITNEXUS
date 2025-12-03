import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'ksit_nexus.settings')
django.setup()

from apps.safety_wellbeing.models import SafetyResource

count = SafetyResource.objects.filter(is_active=True).count()
print(f'Total active safety resources: {count}')

for resource in SafetyResource.objects.filter(is_active=True):
    print(f"  - {resource.title} ({resource.get_resource_type_display()})")
















