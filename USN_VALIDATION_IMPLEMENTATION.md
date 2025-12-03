# 7th Semester Student USN Validation Implementation

## Overview
This document outlines the implementation of 7th-semester student USN validation for the KSIT Nexus project. Only students whose USNs are present in the Excel file can register and login.

## Changes Made

### 1. **Models (`backend/apps/accounts/models.py`)**
   - ✅ Added `AllowedUSN` model to store valid 7th-semester student USNs
     - Fields: `usn` (unique), `branch`, `created_at`, `updated_at`
   - ✅ Added `usn` field to `Student` model
     - Field: `usn` (CharField, optional, stores University Seat Number)

### 2. **Management Command (`backend/apps/accounts/management/commands/import_usns.py`)**
   - ✅ Created command to import USNs from Excel file
   - Reads all sheets from `VII SEM.xls` (or custom file path)
   - Automatically detects USN column in each sheet
   - Handles duplicates and errors gracefully
   - Usage:
     ```bash
     python manage.py import_usns
     python manage.py import_usns --file /path/to/file.xls
     python manage.py import_usns --clear  # Clear existing USNs before importing
     ```

### 3. **Registration (`backend/apps/accounts/views.py`)**
   - ✅ Modified `register()` function:
     - Now requires `usn` field for student registrations
     - Validates USN exists in `AllowedUSN` table before registration
     - Returns error: "Invalid USN. You are not eligible to register." if USN not found
     - Stores USN in Student profile upon successful registration
     - Prevents duplicate USN registrations
     - Auto-populates branch from AllowedUSN if available

### 4. **Login (`backend/apps/accounts/views.py`)**
   - ✅ Modified `login()` function:
     - Validates student USN exists in `AllowedUSN` table before allowing login
     - Returns error: "Invalid USN. You are not eligible to login." if validation fails
   - ✅ Modified `login_with_2fa()` function:
     - Added same USN validation for 2FA login flow

### 5. **Serializers (`backend/apps/accounts/serializers.py`)**
   - ✅ Updated `StudentSerializer` to include `usn` field
   - ✅ Updated `StudentProfileNestedSerializer` to include `usn` field
   - ✅ Updated `StudentCreateSerializer` to include `usn` field
   - ✅ Added USN validation in `StudentCreateSerializer.validate_usn()`

### 6. **Admin (`backend/apps/accounts/admin.py`)**
   - ✅ Added `AllowedUSNAdmin` for managing allowed USNs
   - ✅ Updated `StudentAdmin` to display and search by USN

### 7. **Dependencies (`backend/requirements.txt`)**
   - ✅ Added `pandas==2.1.4` for Excel file reading
   - ✅ Added `openpyxl==3.1.2` for Excel file support

## Migration Steps

### Step 1: Install Dependencies
```bash
cd backend
pip install -r requirements.txt
```

### Step 2: Create and Run Migrations
```bash
python manage.py makemigrations accounts
python manage.py migrate accounts
```

### Step 3: Import USNs from Excel File
```bash
# Make sure the Excel file is at: C:\Users\Samhita P\OneDrive\Desktop\KSIT NEXUS - Copy\VII SEM.xls
# Or specify custom path:
python manage.py import_usns --file "path/to/VII SEM.xls"

# To clear existing USNs and reimport:
python manage.py import_usns --clear
```

### Step 4: Verify Import
- Check Django admin: `/admin/accounts/allowedusn/`
- Or use Django shell:
  ```python
  from apps.accounts.models import AllowedUSN
  print(f"Total allowed USNs: {AllowedUSN.objects.count()}")
  ```

## API Changes

### Registration Endpoint
**Before:**
```json
{
  "email": "student@example.com",
  "username": "student123",
  "password": "password123",
  "first_name": "John",
  "last_name": "Doe",
  "user_type": "student",
  "phone_number": "+1234567890"
}
```

**After (for students):**
```json
{
  "email": "student@example.com",
  "username": "student123",
  "password": "password123",
  "first_name": "John",
  "last_name": "Doe",
  "user_type": "student",
  "phone_number": "+1234567890",
  "usn": "1KS23CS001"  // REQUIRED for students
}
```

### Error Responses

**Registration - Invalid USN:**
```json
{
  "error": "Invalid USN. You are not eligible to register."
}
```

**Login - Invalid USN:**
```json
{
  "error": "Invalid USN. You are not eligible to login."
}
```

## Validation Rules

1. **Registration:**
   - USN is required for students
   - USN must exist in `AllowedUSN` table
   - USN cannot be already registered by another student

2. **Login:**
   - Student must have USN in their profile
   - USN must exist in `AllowedUSN` table
   - Students without valid USN are rejected

3. **USN Format:**
   - Stored in uppercase
   - Trimmed of whitespace
   - Minimum 5 characters

## Files Modified

1. `backend/apps/accounts/models.py` - Added AllowedUSN model and usn field to Student
2. `backend/apps/accounts/views.py` - Modified registration and login views
3. `backend/apps/accounts/serializers.py` - Updated serializers with USN field
4. `backend/apps/accounts/admin.py` - Added AllowedUSN admin and updated Student admin
5. `backend/requirements.txt` - Added pandas and openpyxl
6. `backend/apps/accounts/management/commands/import_usns.py` - NEW: Management command

## Testing

### Test Registration
```bash
curl -X POST http://localhost:8000/api/accounts/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "username": "testuser",
    "password": "testpass123",
    "first_name": "Test",
    "last_name": "User",
    "user_type": "student",
    "usn": "1KS23CS001"
  }'
```

### Test Login
```bash
curl -X POST http://localhost:8000/api/accounts/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "testpass123"
  }'
```

## Notes

- ✅ Faculty and Admin users are NOT affected by USN validation
- ✅ Only students are required to have valid USN
- ✅ Existing students without USN will be blocked from login
- ✅ USN validation is case-insensitive (stored in uppercase)
- ✅ Branch is auto-populated from Excel sheet name when importing USNs

## Troubleshooting

1. **Import fails:**
   - Check Excel file path
   - Verify file format (.xls or .xlsx)
   - Check column names match expected patterns

2. **USN validation fails:**
   - Verify USN was imported successfully
   - Check USN format matches exactly (case-insensitive)
   - Verify student profile has USN set

3. **Login rejected:**
   - Ensure student profile has USN
   - Verify USN exists in AllowedUSN table
   - Check if USN was removed from AllowedUSN table


