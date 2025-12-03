#!/usr/bin/env python
"""Verify complete import of USNs and names from Excel"""
import os
import django
import pandas as pd

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'ksit_nexus.settings')
django.setup()

from apps.accounts.models import AllowedUSN

file_path = r"C:\Users\Samhita P\OneDrive\Desktop\KSIT NEXUS - Copy\VII SEM.xls"
excel_file = pd.ExcelFile(file_path)

print("="*80)
print("VERIFYING COMPLETE IMPORT FROM EXCEL FILE")
print("="*80)

# Get all USNs from database
db_usns = set(AllowedUSN.objects.values_list('usn', flat=True))
print(f"\nUSNs in database: {len(db_usns)}")

# Check each sheet
total_excel_usns = 0
total_excel_names = 0
missing_usns = []
sheet_details = []

for sheet_name in excel_file.sheet_names:
    if sheet_name in ['Sheet1', 'Sheet2', 'Sheet3', 'Sheet4']:
        continue  # Skip summary sheets
    
    print(f"\n{'='*60}")
    print(f"Sheet: {sheet_name}")
    print(f"{'='*60}")
    
    try:
        df = pd.read_excel(excel_file, sheet_name=sheet_name)
        
        # Find USN column
        usn_column = None
        name_column = None
        
        # Try to find USN column
        for col in df.columns:
            sample = df[col].dropna().head(10).astype(str)
            usn_count = 0
            for val in sample:
                val_str = str(val).strip().upper()
                if (len(val_str) >= 8 and val_str[0].isdigit() and 
                    'KS' in val_str and any(c.isalpha() for c in val_str)):
                    usn_count += 1
            if usn_count >= 3:
                usn_column = col
                break
        
        # Try to find name column
        for col in df.columns:
            sample = df[col].dropna().head(10).astype(str)
            name_count = 0
            for val in sample:
                val_str = str(val).strip()
                # Names typically have spaces, letters, and are longer
                if (len(val_str) > 5 and 
                    ' ' in val_str and
                    val_str.replace(' ', '').isalpha() and
                    val_str.upper() not in ['ADMISSION', 'CANCELLED', 'DETAINED']):
                    name_count += 1
            if name_count >= 3:
                name_column = col
                break
        
        # Extract USNs
        excel_usns = set()
        excel_names = {}
        
        if usn_column:
            for idx, usn in df[usn_column].items():
                usn_str = str(usn).strip().upper()
                if (len(usn_str) >= 8 and usn_str[0].isdigit() and 
                    'KS' in usn_str and any(c.isalpha() for c in usn_str)):
                    excel_usns.add(usn_str)
                    # Try to get corresponding name
                    if name_column:
                        name_val = df.loc[idx, name_column]
                        if pd.notna(name_val):
                            excel_names[usn_str] = str(name_val).strip()
        
        # Also scan all columns for USNs
        all_usns_in_sheet = set()
        for col in df.columns:
            for idx, val in df[col].items():
                val_str = str(val).strip().upper()
                if (len(val_str) >= 8 and val_str[0].isdigit() and 
                    'KS' in val_str and any(c.isalpha() for c in val_str)):
                    all_usns_in_sheet.add(val_str)
        
        excel_usns = excel_usns.union(all_usns_in_sheet)
        
        # Check which USNs are missing from database
        missing = excel_usns - db_usns
        
        print(f"  USNs in Excel: {len(excel_usns)}")
        print(f"  Names found: {len(excel_names)}")
        print(f"  USNs in DB: {len([u for u in excel_usns if u in db_usns])}")
        print(f"  Missing from DB: {len(missing)}")
        
        if missing:
            print(f"  Missing USNs: {list(missing)[:10]}")
            missing_usns.extend(missing)
        
        total_excel_usns += len(excel_usns)
        total_excel_names += len(excel_names)
        
        sheet_details.append({
            'sheet': sheet_name,
            'excel_usns': len(excel_usns),
            'db_usns': len([u for u in excel_usns if u in db_usns]),
            'missing': len(missing),
            'names': len(excel_names)
        })
        
    except Exception as e:
        print(f"  Error processing sheet: {e}")
        import traceback
        traceback.print_exc()

print(f"\n{'='*80}")
print("SUMMARY")
print(f"{'='*80}")
print(f"Total USNs in Excel (all sheets): {total_excel_usns}")
print(f"Total USNs in Database: {len(db_usns)}")
print(f"Missing USNs: {len(missing_usns)}")
print(f"Total Names found in Excel: {total_excel_names}")

if missing_usns:
    print(f"\n⚠️  MISSING USNs ({len(missing_usns)}):")
    for usn in list(missing_usns)[:20]:
        print(f"  - {usn}")
    if len(missing_usns) > 20:
        print(f"  ... and {len(missing_usns) - 20} more")

print(f"\n{'='*80}")
print("SHEET-BY-SHEET BREAKDOWN")
print(f"{'='*80}")
for detail in sheet_details:
    print(f"{detail['sheet']:10} | Excel: {detail['excel_usns']:4} | DB: {detail['db_usns']:4} | Missing: {detail['missing']:4} | Names: {detail['names']:4}")

# Check if names are stored
print(f"\n{'='*80}")
print("CHECKING IF NAMES ARE STORED IN DATABASE")
print(f"{'='*80}")
sample_usn = AllowedUSN.objects.first()
if sample_usn:
    print(f"Sample AllowedUSN fields: {[f.name for f in AllowedUSN._meta.get_fields()]}")
    print(f"Current model fields: usn, branch, created_at, updated_at")
    print("⚠️  NAMES ARE NOT CURRENTLY STORED IN DATABASE")

