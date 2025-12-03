from django.contrib.auth import get_user_model
from apps.accounts.models import Student, Faculty

User = get_user_model()

def create_user(username, email, password, full_name, is_student=False, is_faculty=False):
    if User.objects.filter(username=username).exists():
        print("User already exists:", username)
        return

    first_name = full_name.split()[0]
    last_name = " ".join(full_name.split()[1:]) if len(full_name.split()) > 1 else ""

    user = User.objects.create_user(
        username=username,
        email=email,
        password=password,
        first_name=first_name,
        last_name=last_name,
    )

    if is_student:
        Student.objects.create(user=user)
        print("Student created:", username)

    if is_faculty:
        Faculty.objects.create(user=user)
        print("Faculty created:", username)


# Create 5 students
create_user("samhita", "samhita@gmail.com", "Sam@123", "Samhita P", is_student=True)
create_user("umesh", "umesh@gmail.com", "Sam@123", "Umesh Bhatta", is_student=True)
create_user("vignesh", "vignesh@gmail.com", "Sam@123", "Vignesh S", is_student=True)
create_user("shreya", "shreya@gmail.com", "Sam@123", "Shreya Murthy", is_student=True)
create_user("sangeetha", "sangeetha@gmail.com", "Sam@123", "Sangeetha S", is_student=True)

# Create 5 faculty
create_user("prashanth", "prashanth@gmail.com", "Sam@123", "Prashanth HS", is_faculty=True)
create_user("krishna", "krishna@gmail.com", "Sam@123", "Krishna Gudi", is_faculty=True)
create_user("roopesh", "roopesh@gmail.com", "Sam@123", "Roopesh Kumar", is_faculty=True)
create_user("kumar", "kumar@gmail.com", "Sam@123", "Kumar K", is_faculty=True)
create_user("raghavendra", "raghavendra@gmail.com", "Sam@123", "Raghavendrachar S", is_faculty=True)

print("USER CREATION COMPLETE!")
