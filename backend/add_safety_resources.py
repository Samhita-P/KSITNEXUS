"""
Script to add sample safety resources to the database
Run with: python manage.py shell < add_safety_resources.py
Or: python manage.py shell, then copy-paste this code
"""
import os
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'ksit_nexus.settings')
django.setup()

from apps.safety_wellbeing.models import SafetyResource

# Sample safety resources data
safety_resources = [
    {
        'title': 'Campus Safety Guide',
        'resource_type': 'guide',
        'description': 'Comprehensive guide on staying safe on campus, including emergency procedures, reporting incidents, and safety tips.',
        'content': '''
# Campus Safety Guide

## Emergency Contacts
- Campus Security: 24/7 Hotline - (555) 123-4567
- Medical Emergency: (555) 911
- Campus Police: (555) 123-4568

## Safety Tips
1. Always be aware of your surroundings
2. Walk in well-lit areas at night
3. Keep your phone charged and accessible
4. Share your location with trusted contacts
5. Report suspicious activity immediately

## Emergency Procedures
- Fire: Evacuate immediately, call 911
- Medical: Call campus medical services
- Security Threat: Contact campus security immediately
        ''',
        'url': None,
        'tags': ['safety', 'emergency', 'campus', 'guide'],
        'is_featured': True,
        'is_active': True,
    },
    {
        'title': 'Mental Health Support Resources',
        'resource_type': 'article',
        'description': 'Information about mental health support services available on campus, including counseling services, crisis hotlines, and self-care resources.',
        'content': '''
# Mental Health Support Resources

## On-Campus Services
- Counseling Center: Available Monday-Friday, 9 AM - 5 PM
- 24/7 Crisis Hotline: (555) 123-HELP
- Peer Support Groups: Weekly meetings

## Self-Care Tips
- Practice mindfulness and meditation
- Maintain a regular sleep schedule
- Stay connected with friends and family
- Exercise regularly
- Seek professional help when needed

## External Resources
- National Suicide Prevention Lifeline: 988
- Crisis Text Line: Text HOME to 741741
        ''',
        'url': 'https://www.example.com/mental-health',
        'tags': ['mental-health', 'counseling', 'support', 'wellbeing'],
        'is_featured': True,
        'is_active': True,
    },
    {
        'title': 'Cybersecurity Best Practices',
        'resource_type': 'guide',
        'description': 'Essential cybersecurity tips to protect your personal information and devices while on campus.',
        'content': '''
# Cybersecurity Best Practices

## Password Security
- Use strong, unique passwords
- Enable two-factor authentication
- Never share your passwords
- Use a password manager

## Network Safety
- Use secure Wi-Fi networks
- Avoid public Wi-Fi for sensitive activities
- Use VPN when necessary
- Keep your devices updated

## Phishing Awareness
- Be cautious of suspicious emails
- Verify sender identity
- Don't click unknown links
- Report phishing attempts
        ''',
        'url': None,
        'tags': ['cybersecurity', 'privacy', 'technology', 'safety'],
        'is_featured': False,
        'is_active': True,
    },
    {
        'title': 'First Aid Basics Video',
        'resource_type': 'video',
        'description': 'Learn essential first aid techniques including CPR, treating cuts and burns, and handling medical emergencies.',
        'content': None,
        'url': 'https://www.youtube.com/watch?v=example',
        'tags': ['first-aid', 'medical', 'emergency', 'video'],
        'is_featured': True,
        'is_active': True,
    },
    {
        'title': 'Campus Emergency Contacts Directory',
        'resource_type': 'contact',
        'description': 'Quick reference directory of all important emergency contacts on campus including security, medical, and administrative offices.',
        'content': '''
# Campus Emergency Contacts

## Security & Safety
- Campus Security: (555) 123-4567 (24/7)
- Campus Police: (555) 123-4568
- Emergency Services: 911

## Medical Services
- Health Center: (555) 123-4569
- Mental Health Crisis: (555) 123-HELP
- After-Hours Medical: (555) 123-4570

## Administrative
- Student Affairs: (555) 123-4571
- Dean of Students: (555) 123-4572
- Title IX Office: (555) 123-4573
        ''',
        'url': None,
        'tags': ['contacts', 'emergency', 'directory', 'campus'],
        'is_featured': True,
        'is_active': True,
    },
    {
        'title': 'Safe Transportation Guide',
        'resource_type': 'guide',
        'description': 'Guidelines for safe transportation on and around campus, including walking, biking, public transit, and rideshare safety.',
        'content': '''
# Safe Transportation Guide

## Walking Safety
- Use well-lit paths
- Walk with friends when possible
- Stay alert and avoid distractions
- Carry a personal safety device

## Public Transportation
- Know your route before traveling
- Stay in well-lit areas while waiting
- Keep valuables secure
- Trust your instincts

## Rideshare Safety
- Verify driver and vehicle details
- Share trip details with friends
- Sit in the back seat
- Have emergency contacts ready
        ''',
        'url': None,
        'tags': ['transportation', 'safety', 'travel', 'campus'],
        'is_featured': False,
        'is_active': True,
    },
    {
        'title': 'Campus Safety Mobile App',
        'resource_type': 'tool',
        'description': 'Download our official campus safety mobile app for quick access to emergency contacts, safety alerts, and reporting tools.',
        'content': None,
        'url': 'https://apps.example.com/safety',
        'tags': ['app', 'mobile', 'safety', 'technology'],
        'is_featured': True,
        'is_active': True,
    },
    {
        'title': 'Preventing Sexual Assault',
        'resource_type': 'article',
        'description': 'Important information about preventing sexual assault, recognizing warning signs, and resources for survivors.',
        'content': '''
# Preventing Sexual Assault

## Prevention Strategies
- Trust your instincts
- Set clear boundaries
- Stay with trusted friends
- Avoid excessive alcohol consumption
- Have a safety plan

## Resources for Survivors
- Campus Title IX Office
- Counseling Services
- Support Groups
- Legal Assistance
- Medical Services

## Reporting Options
- Campus Security
- Title IX Coordinator
- Local Law Enforcement
- Anonymous Reporting Available
        ''',
        'url': None,
        'tags': ['sexual-assault', 'prevention', 'support', 'safety'],
        'is_featured': True,
        'is_active': True,
    },
]

def add_safety_resources():
    """Add sample safety resources to the database"""
    created_count = 0
    skipped_count = 0
    
    for resource_data in safety_resources:
        # Check if resource already exists
        existing = SafetyResource.objects.filter(title=resource_data['title']).first()
        if existing:
            print(f"Resource '{resource_data['title']}' already exists. Skipping...")
            skipped_count += 1
            continue
        
        # Create the resource
        resource = SafetyResource.objects.create(**resource_data)
        print(f"Created safety resource: {resource.title} ({resource.get_resource_type_display()})")
        created_count += 1
    
    print(f"\n{'='*60}")
    print(f"Summary:")
    print(f"  Created: {created_count} resources")
    print(f"  Skipped: {skipped_count} resources (already exist)")
    print(f"{'='*60}")

if __name__ == '__main__':
    add_safety_resources()
















