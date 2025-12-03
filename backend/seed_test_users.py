# backend/seed_test_users.py
# Safe, Render-compatible test user seeding script
# Includes USNs for students + correct handling for faculty

from django.db import IntegrityError, transaction
from django.contrib.auth import get_user_model

User = get_user_model()

# Import related models safely
try:
    from apps.accounts.models import Student, Faculty
except Exception:
    Student = None
    Faculty = None


# -----------------------------
# HELPERS
# -----------------------------
def create_user(email, password, full_name, is_student=False, is_faculty=False, usn=None):
    username_for_auth = email  # login using email

    first_name = full_name.split()[0]
    last_name = " ".join(full_name.split()[1:]) if len(full_name.split()) > 1 else ""

    # If user already exists → return existing user
    existing = User.objects.filter(username=username_for_auth).first()
    if existing:
        print(f"User already exists: {email}")
        return existing

    try:
        with transaction.atomic():
            user = User.objects.create_user(
                username=username_for_auth,
                email=email,
                password=password,
                first_name=first_name,
                last_name=last_name,
            )

            # --- STUDENT CREATION ---
            if is_student and Student is not None:
                try:
                    Student.objects.create(
                        user=user,
                        usn=usn,
                        year_of_study=3,      # Default safe value
                        section="C",           # Default
                        branch="CSE"           # Default
                    )
                    print(f"✔ Student created: {email} ({usn})")
                except IntegrityError as e:
                    print(f"⚠️ Student creation failed for {email}: {e}")

            # --- FACULTY CREATION ---
            if is_faculty and Faculty is not None:
                try:
                    Faculty.objects.create(
                        user=user,
                        designation="Assistant Professor",
                        employee_id=f"EMP{user.id:03d}"   # Auto-generate employee ID
                    )
                    print(f"✔ Faculty created: {email}")
                except IntegrityError as e:
                    print(f"⚠️ Faculty creation failed for {email}: {e}")

            print(f"✔ User created: {email}")
            return user

    except Exception as e:
        print(f"✖ Unexpected error creating user {email}: {e}")


# -----------------------------
# RUN SEEDING
# -----------------------------
def run():
    print("➡️ Seeding test users...")

    password = "Sam@123"

    # --- Student list with USNs ---
    students = [
        ("samhita@gmail.com",   "Samhita P",      "1KS22CS130"),
        ("umesh@gmail.com",     "Umesh Bhatta",   "1KS22CS176"),
        ("vignesh@gmail.com",   "Vignesh S",      "1KS22CS184"),
        ("shreya@gmail.com",    "Shreya Murthy",  "1KS22CS146"),
        ("sangeetha@gmail.com", "Sangeetha S",    "1KS22CS135"),
    ]

    faculty = [
        ("prashanth@gmail.com", "Prashanth HS"),
        ("krishna@gmail.com",   "Krishna Gudi"),
        ("roopesh@gmail.com",   "Roopesh Kumar"),
        ("kumar@gmail.com",     "Kumar K"),
        ("raghavendra@gmail.com", "Raghavendrachar S"),
    ]

    # Ensure admin exists
    if not User.objects.filter(username="admin").exists():
        User.objects.create_superuser("admin", "admin@example.com", "Admin@123")
        print("✔ Superuser created")
    else:
        print("✔ Superuser already exists")

    # Seed students
    for email, fullname, usn in students:
        create_user(email, password, fullname, is_student=True, usn=usn)

    # Seed faculty
    for email, fullname in faculty:
        create_user(email, password, fullname, is_faculty=True)

    print("🎉 USER SEEDING COMPLETE!")


# Auto-run when executed via: python manage.py shell < seed_test_users.py
if __name__ == "__main__":
    run()
else:
    run()
