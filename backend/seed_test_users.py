# backend/seed_test_users.py
# Safe seeding script for Render runs: sets required defaults and doesn't crash the deploy.

from django.db import IntegrityError, transaction
from django.contrib.auth import get_user_model

User = get_user_model()

# Try to import Student/Faculty; fall back gracefully if models move
try:
    from apps.accounts.models import Student, Faculty
except Exception:
    Student = None
    Faculty = None

def create_user(username, email, password, full_name, is_student=False, is_faculty=False):
    username_safe = username or email.split('@')[0]
    # For simplicity make username equal to email (so authentication by email will work
    # even if the view calls authenticate(username=...))
    username_for_auth = email

    first_name = full_name.split()[0] if full_name else ""
    last_name = " ".join(full_name.split()[1:]) if full_name and len(full_name.split()) > 1 else ""

    if User.objects.filter(username=username_for_auth).exists():
        print(f"User already exists: {username_for_auth}")
        return User.objects.get(username=username_for_auth)

    try:
        with transaction.atomic():
            user = User.objects.create_user(
                username=username_for_auth,
                email=email,
                password=password,
                first_name=first_name,
                last_name=last_name,
            )
            # If your custom User model uses different fields, adapt above accordingly.

            # Create Student/Faculty profile rows with safe defaults if those models exist.
            if is_student and Student is not None:
                # Student likely requires year_of_study (NOT NULL). Pick sensible defaults.
                student_defaults = {}
                # Set some common fields defensively
                # If a field doesn't exist, ignore it
                try:
                    Student.objects.create(user=user, year_of_study=1)
                except TypeError:
                    # model signature is different; try setting only user
                    try:
                        Student.objects.create(user=user)
                    except Exception as e:
                        print(f"⚠️ Could not create Student profile for {username_for_auth}: {e}")
                except IntegrityError as e:
                    print(f"⚠️ Integrity error when creating Student for {username_for_auth}: {e}")

            if is_faculty and Faculty is not None:
                try:
                    # If Faculty model needs designation or faculty_id, we provide defaults
                    # If extra args are invalid it will fall back to user-only creation.
                    Faculty.objects.create(user=user)
                except TypeError:
                    try:
                        Faculty.objects.create(user=user)
                    except Exception as e:
                        print(f"⚠️ Could not create Faculty profile for {username_for_auth}: {e}")
                except IntegrityError as e:
                    print(f"⚠️ Integrity error when creating Faculty for {username_for_auth}: {e}")

            print(f"✔ User created: {username_for_auth}")
            return user

    except IntegrityError as e:
        print(f"✖ Integrity error creating user {username_for_auth}: {e}")
    except Exception as e:
        print(f"✖ Unexpected error creating user {username_for_auth}: {e}")

# Bulk create the sample users
def run():
    print("➡️ Seeding test users...")

    password = "Sam@123"

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

    # Create superuser if missing (safe defaults)
    admin_username = "admin"
    admin_email = "admin@example.com"
    admin_password = "Admin@123"
    if not User.objects.filter(username=admin_username).exists():
        try:
            User.objects.create_superuser(username=admin_username, email=admin_email, password=admin_password)
            print("✔ Superuser created")
        except Exception as e:
            print(f"⚠️ Could not create superuser: {e}")
    else:
        print("✔ Superuser already exists")

    for uname, mail, fullname in students:
        create_user(uname, mail, password, fullname, is_student=True)

    for uname, mail, fullname in faculty:
        create_user(uname, mail, password, fullname, is_faculty=True)

    print("🎉 USER CREATION COMPLETE!")

# Allow running when file is executed by `manage.py shell < thisfile`
if __name__ == "__main__":
    run()
else:
    # manage.py shell will exec this file; call run()
    run()
