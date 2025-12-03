import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'ksit_nexus.settings')
django.setup()

from apps.safety_wellbeing.models import SafetyResource

# Real URLs for safety resources
url_mapping = {
    'First Aid Basics Video': 'https://www.redcross.org/get-help/how-to-prepare-for-emergencies/types-of-emergencies',
    'Mental Health Support Resources': 'https://www.samhsa.gov/find-help/national-helpline',
    'Campus Safety Mobile App': 'https://www.safetrekapp.com/',
    'Preventing Sexual Assault': 'https://www.rainn.org/',
    'Cybersecurity Best Practices': 'https://www.cisa.gov/cybersecurity-awareness-month',
    'Safe Transportation Guide': 'https://www.nhtsa.gov/road-safety',
}

updated_count = 0
for title, url in url_mapping.items():
    resource = SafetyResource.objects.filter(title=title).first()
    if resource:
        resource.url = url
        resource.save()
        print(f"Updated: {title} -> {url}")
        updated_count += 1
    else:
        print(f"Not found: {title}")

print(f"\nUpdated {updated_count} resources with real URLs.")
















