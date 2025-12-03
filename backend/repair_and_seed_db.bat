@echo off
REM KSIT Nexus – FULL Render Backend Database Repair + Test Accounts Seeder

REM Step 1 — Navigate to backend directory
cd /d "%~dp0"

REM Step 2 — Make migrations
echo ➡️ Making migrations...
python manage.py makemigrations --noinput

REM Step 3 — Apply migrations
echo ➡️ Applying migrations...
python manage.py migrate --noinput

REM Step 4 — Create superuser + 5 students + 5 faculty
echo ➡️ Creating default users...
python seed_test_users.py

REM Step 5 — Success Message
echo 🎉 DATABASE FIXED AND SEEDED!

pause

