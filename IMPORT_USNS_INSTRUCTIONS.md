# Import USNs from Excel File - Step by Step Instructions

## Current Status
✅ **Model Created**: `AllowedUSN` model exists in database
✅ **Migration Created**: Migration file `0005_student_usn_allowedusn.py` exists
✅ **Import Command Created**: `import_usns.py` management command is ready
❌ **USNs NOT Imported**: USNs from Excel file are NOT yet in the database

## Steps to Import USNs

### Step 1: Ensure Migrations are Applied
```bash
cd backend
python manage.py migrate accounts
```

### Step 2: Install Required Dependencies (if not already installed)
```bash
pip install pandas==2.1.4 openpyxl==3.1.2
```

### Step 3: Import USNs from Excel File
```bash
# Option 1: Use default location (project root/VII SEM.xls)
python manage.py import_usns

# Option 2: Specify custom file path
python manage.py import_usns --file "C:\Users\Samhita P\OneDrive\Desktop\KSIT NEXUS - Copy\VII SEM.xls"

# Option 3: Clear existing USNs and reimport
python manage.py import_usns --clear
```

### Step 4: Verify Import
After running the import command, you should see output like:
```
Reading Excel file: C:\Users\Samhita P\OneDrive\Desktop\KSIT NEXUS - Copy\VII SEM.xls
Found 5 sheet(s): CSE, IOT, ISE, ECE, EEE
Processing sheet: CSE
  Rows in sheet: 120
  Valid USNs found: 120
  Sheet "CSE": Imported 120 USN(s)
...
============================================================
Import Summary:
  Total USNs processed: 500
  New USNs imported: 500
  Existing USNs skipped: 0
  Errors: 0
  Total USNs in database: 500
============================================================
```

### Step 5: Check Database (Optional)
You can verify USNs are in the database by:
1. Using Django admin: Go to `/admin/accounts/allowedusn/`
2. Using Django shell:
```bash
python manage.py shell
>>> from apps.accounts.models import AllowedUSN
>>> print(f"Total USNs: {AllowedUSN.objects.count()}")
>>> AllowedUSN.objects.all()[:10]  # Show first 10
```

## What the Import Command Does

1. **Reads Excel File**: Opens `VII SEM.xls` from project root
2. **Processes All Sheets**: Reads every sheet (CSE, IOT, ISE, etc.)
3. **Auto-detects USN Column**: Finds the USN column automatically
4. **Extracts USNs**: Gets all valid USNs from each sheet
5. **Stores in Database**: Saves to `AllowedUSN` table
6. **Handles Duplicates**: Skips USNs that already exist
7. **Stores Branch Info**: Uses sheet name as branch name

## Important Notes

- USNs are stored in **uppercase** for consistency
- Duplicate USNs are automatically skipped
- Each sheet name becomes the branch name
- Minimum USN length is 5 characters
- Empty or invalid USNs are filtered out

## Troubleshooting

**Error: Excel file not found**
- Make sure `VII SEM.xls` is in the project root directory
- Or use `--file` option to specify full path

**Error: pandas not found**
- Run: `pip install pandas openpyxl`

**Error: No USNs imported**
- Check if Excel file has USN column
- Verify column name matches: USN, usn, USN_NO, etc.
- Check command output for warnings


