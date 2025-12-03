import os
from django.contrib.auth import get_user_model
from apps.accounts.models import Student, Faculty

User = get_user_model()

def create_user(username, email, password, full_name, is_student=False, is_faculty=False):
    first_name = full_name.split()[0]
    last_name = " ".join(full_name.split()[1:]) if len(full_name.split()) > 1 else ""

    user, created = User.objects.get_or_create(
        username=username,
        defaults={
            "email": email,
            "password": password,
            "first_name": first_name,
            "last_name": last_name,
        }
    )

    if created:
        user.set_password(password)
        user.save()

        if is_student:
            Student.objects.get_or_create(user=user)
            print("✔ Student created:", username)

        if is_faculty:
            Faculty.objects.get_or_create(user=user)
            print("✔ Faculty created:", username)

    else:
        print("User already exists:", username)


# --- Create test users ---

students = [
    ("samhita", "samhita@gmail.com", "Samhita P"),
    ("umesh", "umesh@gmail.com", "Umesh Bhatta"),
    ("vignesh", "vignesh@gmail.com", "Vignesh S"),
    ("shreya", "shreya@gmail.com", "Shreya Murthy"),
    ("sangeetha", "sangeetha@gmail.com", "Sangeetha S"),
]

faculty = [
    ("prashanth", "prashanth@gmail.com", "Prashanth HS"),
    ("krishna", "krishna@gmail.com", "Krishna Gudi"),
    ("roopesh", "roopesh@gmail.com", "Roopesh Kumar"),
    ("kumar", "kumar@gmail.com", "Kumar K"),
    ("raghavendra", "raghavendra@gmail.com", "Raghavendrachar S"),
]

for u, e, n in students:
    create_user(u, e, "Sam@123", n, is_student=True)

for u, e, n in faculty:
    create_user(u, e, "Sam@123", n, is_faculty=True)

print("🎉 USER CREATION COMPLETE!")
