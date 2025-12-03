#!/bin/bash

# KSIT Nexus – FULL Render Backend Database Repair + Test Accounts Seeder

# Step 1 — Navigate to backend directory
cd "$(dirname "$0")"

# Step 2 — Make migrations
echo "➡️ Making migrations..."
python manage.py makemigrations --noinput

# Step 3 — Apply migrations
echo "➡️ Applying migrations..."
python manage.py migrate --noinput

# Step 4 — Create superuser + 5 students + 5 faculty
echo "➡️ Creating default users..."
python seed_test_users.py

# Step 5 — Success Message
echo '🎉 DATABASE FIXED AND SEEDED!'

