"""
Management command to import USNs from Excel file
"""
import os
import pandas as pd
from django.core.management.base import BaseCommand
from django.conf import settings
from apps.accounts.models import AllowedUSN


class Command(BaseCommand):
    help = 'Import USNs from Excel file (VII SEM.xls) located in project root'

    def add_arguments(self, parser):
        parser.add_argument(
            '--file',
            type=str,
            default=None,
            help='Path to Excel file. If not provided, will look for VII SEM.xls in project root',
        )
        parser.add_argument(
            '--clear',
            action='store_true',
            help='Clear existing USNs before importing',
        )

    def handle(self, *args, **options):
        file_path = options.get('file')
        
        # If file path not provided, use default location
        if not file_path:
            # Get project root (parent of backend)
            project_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
            file_path = os.path.join(project_root, 'VII SEM.xls')
        
        if not os.path.exists(file_path):
            self.stdout.write(
                self.style.ERROR(f'Excel file not found at: {file_path}')
            )
            return
        
        self.stdout.write(f'Reading Excel file: {file_path}')
        
        try:
            # Read all sheets from Excel file
            excel_file = pd.ExcelFile(file_path)
            sheet_names = excel_file.sheet_names
            
            self.stdout.write(f'Found {len(sheet_names)} sheet(s): {", ".join(sheet_names)}')
            
            # Clear existing USNs if requested
            if options.get('clear'):
                deleted_count = AllowedUSN.objects.all().delete()[0]
                self.stdout.write(
                    self.style.WARNING(f'Cleared {deleted_count} existing USN(s)')
                )
            
            total_usns = 0
            imported_count = 0
            skipped_count = 0
            error_count = 0
            
            # Process each sheet
            for sheet_name in sheet_names:
                self.stdout.write(f'\nProcessing sheet: {sheet_name}')
                
                try:
                    # Try reading with different header positions
                    df = None
                    header_row = 0
                    
                    # Try different header row positions
                    for header_try in [0, 1, 2]:
                        try:
                            df = pd.read_excel(excel_file, sheet_name=sheet_name, header=header_try)
                            if len(df.columns) > 0 and len(df) > 0:
                                header_row = header_try
                                break
                        except:
                            continue
                    
                    if df is None or len(df) == 0:
                        self.stdout.write(
                            self.style.WARNING(f'  Empty sheet or could not read: {sheet_name}')
                        )
                        continue
                    
                    self.stdout.write(f'  Rows in sheet: {len(df)}')
                    
                    # Find USN column - try common column names first
                    usn_column = None
                    best_column_score = 0
                    possible_usn_columns = ['USN', 'usn', 'USN_NO', 'University Seat Number', 
                                           'Student USN', 'Registration Number', 'Reg No',
                                           'REG NO', 'Reg.No', 'REG NO.']
                    
                    # First, try exact column name matches
                    for col in df.columns:
                        if str(col).strip().upper() in [p.upper() for p in possible_usn_columns]:
                            usn_column = col
                            self.stdout.write(f'  Found USN column by name: {usn_column}')
                            break
                    
                    # If not found, try ALL columns and score them
                    if not usn_column:
                        for col in df.columns:
                            # Check ALL rows, not just first 20
                            sample_values = df[col].dropna().head(min(100, len(df))).astype(str)
                            if len(sample_values) == 0:
                                continue
                                
                            usn_pattern_count = 0
                            total_valid = 0
                            
                            for val in sample_values:
                                val_str = str(val).strip().upper()
                                # Skip empty or NaN
                                if val_str.lower() in ['nan', '', 'none', 'null']:
                                    continue
                                
                                total_valid += 1
                                
                                # USN patterns: typically starts with digit, contains letters and numbers
                                # Example: 1KS23CS001, 1KS24EC123, etc.
                                if (len(val_str) >= 8 and 
                                    val_str[0].isdigit() and 
                                    any(c.isalpha() for c in val_str) and
                                    any(c.isdigit() for c in val_str)):
                                    # Check for KS pattern (most common) or other patterns
                                    if ('KS' in val_str or 
                                        val_str.startswith('1') or 
                                        val_str.startswith('2')):
                                        usn_pattern_count += 1
                            
                            if total_valid == 0:
                                continue
                            
                            # Calculate score (percentage of valid USN-like values)
                            score = usn_pattern_count / total_valid if total_valid > 0 else 0
                            
                            # Use this column if score is better than current best
                            if score > best_column_score and score >= 0.15:  # At least 15% should match
                                best_column_score = score
                                usn_column = col
                        
                        if usn_column:
                            self.stdout.write(f'  Auto-detected USN column: {usn_column} (confidence: {best_column_score*100:.1f}%)')
                    
                    if not usn_column:
                        # Last resort: try all columns and get the one with most valid USN patterns
                        self.stdout.write(f'  Trying all columns as potential USN columns...')
                        all_valid_usns = []
                        for col in df.columns:
                            col_usns = []
                            for val in df[col].dropna().astype(str):
                                val_str = str(val).strip().upper()
                                if (len(val_str) >= 8 and 
                                    val_str[0].isdigit() and 
                                    any(c.isalpha() for c in val_str) and
                                    any(c.isdigit() for c in val_str) and
                                    'KS' in val_str):
                                    col_usns.append(val_str)
                            
                            if len(col_usns) > len(all_valid_usns):
                                all_valid_usns = col_usns
                                usn_column = col
                        
                        if usn_column and len(all_valid_usns) > 0:
                            self.stdout.write(f'  Found USN column: {usn_column} with {len(all_valid_usns)} potential USNs')
                            # Use the found USNs
                            valid_usns = list(set(all_valid_usns))
                        else:
                            # Last resort: scan entire dataframe cell by cell
                            self.stdout.write(f'  Scanning entire sheet for USN patterns...')
                            all_cell_usns = set()
                            invalid_patterns = [
                                'ADMISSION', 'CANCELLED', 'DETAINED', 'ARTIFICIAL', 'INTELLIGENCE',
                                'MACHINE', 'LEARNING', 'COMPUTER', 'SCIENCE', 'ENGINEERING',
                                'TECHNOLOGY', 'DUE TO', 'BACKLOG', 'ATTENDANCE', 'EXAM',
                                'K.S.INSTITUTE', 'INSTITUTE OF TECHNOLOGY', 'DEPARTMENT'
                            ]
                            
                            # Scan all cells in the dataframe
                            for col in df.columns:
                                for idx, val in df[col].items():
                                    val_str = str(val).strip().upper()
                                    if (val_str and 
                                        val_str.lower() not in ['nan', 'none', 'null', ''] and
                                        len(val_str) >= 8 and 
                                        val_str[0].isdigit() and
                                        any(c.isalpha() for c in val_str) and
                                        any(c.isdigit() for c in val_str) and
                                        'KS' in val_str and
                                        not any(pattern in val_str for pattern in invalid_patterns)):
                                        all_cell_usns.add(val_str)
                            
                            if len(all_cell_usns) > 0:
                                valid_usns = list(all_cell_usns)
                                self.stdout.write(f'  Found {len(valid_usns)} USNs by scanning all cells')
                                usn_column = 'ALL_COLUMNS'  # Placeholder
                            else:
                                self.stdout.write(
                                    self.style.WARNING(f'  Could not find any USNs in sheet: {sheet_name}')
                                )
                                continue
                    
                    # Find name column (usually adjacent to USN column)
                    name_column = None
                    if usn_column and usn_column != 'ALL_COLUMNS':
                        usn_col_idx = list(df.columns).index(usn_column)
                        # Try columns next to USN column
                        for offset in [1, -1, 2, -2]:
                            try:
                                potential_name_col = df.columns[usn_col_idx + offset]
                                # Check if it looks like a name column
                                sample_names = df[potential_name_col].dropna().head(10).astype(str)
                                name_like_count = 0
                                for val in sample_names:
                                    val_str = str(val).strip()
                                    # Names typically have spaces, letters, and reasonable length
                                    if (len(val_str) > 5 and 
                                        ' ' in val_str and
                                        val_str.replace(' ', '').replace('.', '').isalpha() and
                                        val_str.upper() not in ['ADMISSION', 'CANCELLED', 'DETAINED']):
                                        name_like_count += 1
                                
                                if name_like_count >= 3:
                                    name_column = potential_name_col
                                    self.stdout.write(f'  Auto-detected name column: {name_column}')
                                    break
                            except (IndexError, KeyError):
                                continue
                    
                    # Extract USNs and names from the sheet
                    usn_name_pairs = {}  # {usn: name}
                    invalid_patterns = [
                        'ADMISSION', 'CANCELLED', 'DETAINED', 'ARTIFICIAL', 'INTELLIGENCE',
                        'MACHINE', 'LEARNING', 'COMPUTER', 'SCIENCE', 'ENGINEERING',
                        'TECHNOLOGY', 'DUE TO', 'BACKLOG', 'ATTENDANCE', 'EXAM',
                        'K.S.INSTITUTE', 'INSTITUTE OF TECHNOLOGY', 'DEPARTMENT'
                    ]
                    
                    # First, collect all USNs from all columns (to ensure we get everything)
                    all_usns_found = {}
                    for col in df.columns:
                        for idx, val in df[col].items():
                            val_str = str(val).strip().upper()
                            if (len(val_str) >= 8 and 
                                val_str[0].isdigit() and
                                any(c.isalpha() for c in val_str) and
                                any(c.isdigit() for c in val_str) and
                                'KS' in val_str and
                                not any(pattern in val_str for pattern in invalid_patterns)):
                                # Store row index for this USN
                                if val_str not in all_usns_found:
                                    all_usns_found[val_str] = idx
                    
                    # Now, for each USN found, get the corresponding name from the same row
                    for usn_str, row_idx in all_usns_found.items():
                        row = df.loc[row_idx]
                        name_val = None
                        
                        # Try name column if detected
                        if name_column:
                            name_val = row.get(name_column)
                        
                        # If no name column or name not found, try adjacent columns
                        if not name_val or pd.isna(name_val):
                            # Try columns near USN column
                            if usn_column and usn_column != 'ALL_COLUMNS':
                                try:
                                    usn_col_idx = list(df.columns).index(usn_column)
                                    for offset in [1, -1, 2, -2, 3, -3]:
                                        try:
                                            adj_col = df.columns[usn_col_idx + offset]
                                            candidate = row.get(adj_col)
                                            if pd.notna(candidate):
                                                candidate_str = str(candidate).strip()
                                                if (len(candidate_str) > 5 and ' ' in candidate_str and
                                                    candidate_str.replace(' ', '').replace('.', '').replace(',', '').isalpha()):
                                                    name_val = candidate_str
                                                    break
                                        except (IndexError, KeyError):
                                            continue
                                except ValueError:
                                    pass
                        
                        # If still no name, scan all columns in the row
                        if not name_val or pd.isna(name_val):
                            for col in df.columns:
                                candidate = row.get(col)
                                if pd.notna(candidate):
                                    candidate_str = str(candidate).strip()
                                    # Check if it looks like a name
                                    if (len(candidate_str) > 5 and 
                                        ' ' in candidate_str and
                                        candidate_str.replace(' ', '').replace('.', '').replace(',', '').isalpha() and
                                        candidate_str.upper() not in ['ADMISSION', 'CANCELLED', 'DETAINED']):
                                        name_val = candidate_str
                                        break
                        
                        if name_val and pd.notna(name_val):
                            usn_name_pairs[usn_str] = str(name_val).strip()
                        else:
                            usn_name_pairs[usn_str] = None
                    
                    valid_usns = list(usn_name_pairs.keys())
                    self.stdout.write(f'  Valid USNs found: {len(valid_usns)}')
                    self.stdout.write(f'  Names found: {len([n for n in usn_name_pairs.values() if n])}')
                    
                    # Import USNs with names
                    for usn, name in usn_name_pairs.items():
                        total_usns += 1
                        try:
                            allowed_usn, created = AllowedUSN.objects.get_or_create(
                                usn=usn.upper(),  # Store in uppercase for consistency
                                defaults={
                                    'branch': sheet_name,
                                    'name': name if name else None
                                }
                            )
                            if created:
                                imported_count += 1
                            else:
                                skipped_count += 1
                                # Update branch and name if not set
                                updated = False
                                if sheet_name and not allowed_usn.branch:
                                    allowed_usn.branch = sheet_name
                                    updated = True
                                if name and not allowed_usn.name:
                                    allowed_usn.name = name
                                    updated = True
                                if updated:
                                    allowed_usn.save()
                        except Exception as e:
                            error_count += 1
                            self.stdout.write(
                                self.style.WARNING(f'  Error importing USN {usn}: {str(e)}')
                            )
                    
                    self.stdout.write(f'  Sheet "{sheet_name}": Imported {len(valid_usns)} USN(s)')
                    
                except Exception as e:
                    self.stdout.write(
                        self.style.ERROR(f'  Error processing sheet "{sheet_name}": {str(e)}')
                    )
                    error_count += 1
            
            # Summary
            self.stdout.write('\n' + '='*60)
            self.stdout.write(self.style.SUCCESS('Import Summary:'))
            self.stdout.write(f'  Total USNs processed: {total_usns}')
            self.stdout.write(f'  New USNs imported: {imported_count}')
            self.stdout.write(f'  Existing USNs skipped: {skipped_count}')
            self.stdout.write(f'  Errors: {error_count}')
            self.stdout.write(f'  Total USNs in database: {AllowedUSN.objects.count()}')
            self.stdout.write('='*60)
            
        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f'Error reading Excel file: {str(e)}')
            )
            import traceback
            traceback.print_exc()

