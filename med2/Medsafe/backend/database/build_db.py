import sqlite3
import csv
import os
import sys

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Input CSV Paths
UPDATED_CSV_PATH = os.path.abspath(os.path.join(BASE_DIR, "..", "..", "..", "..", "updated_indian_medicine_data.csv"))
DATASET_CSV_PATH = os.path.abspath(os.path.join(BASE_DIR, "..", "..", "..", "..", "medicine_dataset.csv"))
DB_PATH = os.path.join(BASE_DIR, "medicines.db")

def build_merged_database():
    print("DATABASE BUILDER: Checking input CSV files...")
    if not os.path.exists(UPDATED_CSV_PATH):
        print(f"ERROR: CSV file not found at {UPDATED_CSV_PATH}")
        sys.exit(1)
    if not os.path.exists(DATASET_CSV_PATH):
        print(f"ERROR: CSV file not found at {DATASET_CSV_PATH}")
        sys.exit(1)

    # 1. Parse medicine_dataset.csv (contains substitutes and classifications)
    print("DATABASE BUILDER: Indexing medicine_dataset.csv into memory...")
    dataset_info = {}
    csv.field_size_limit(sys.maxsize)
    
    with open(DATASET_CSV_PATH, mode='r', encoding='utf-8') as f:
        reader = csv.reader(f)
        header = next(reader)
        
        # Header indices:
        # id=0, name=1, substitute0=2, substitute1=3, substitute2=4, substitute3=5, substitute4=6
        # side effects start from 7
        # chemical_class = -4 (column 55)
        # habit_forming = -3 (column 56)
        # therapeutic_class = -2 (column 57)
        # action_class = -1 (column 58)
        
        for row in reader:
            if not row:
                continue
            try:
                row_id = int(row[0])
                
                # Extract substitutes (collect up to 5 non-empty substitutes)
                subs = [row[i].strip() for i in range(2, 7) if i < len(row) and row[i].strip()]
                substitutes_str = ", ".join(subs)
                
                # Pull classifications (using standard column index logic)
                chemical = row[54].strip() if len(row) > 54 else ""
                habit = row[55].strip() if len(row) > 55 else ""
                therapeutic = row[56].strip() if len(row) > 56 else ""
                
                dataset_info[row_id] = {
                    'substitutes': substitutes_str,
                    'chemical_class': chemical,
                    'habit_forming': habit,
                    'therapeutic_class': therapeutic
                }
            except Exception as e:
                pass

    print(f"DATABASE BUILDER: Completed memory indexing of {len(dataset_info)} records.")

    # 2. Initialize SQLite Database
    print("DATABASE BUILDER: Initializing SQLite database...")
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("DROP TABLE IF EXISTS medicines")

    cursor.execute("""
    CREATE TABLE medicines (
        id INTEGER PRIMARY KEY,
        name TEXT,
        price REAL,
        manufacturer_name TEXT,
        pack_size_label TEXT,
        generic_name TEXT,
        side_effects TEXT,
        drug_interactions TEXT,
        medicine_desc TEXT,
        substitutes TEXT,
        chemical_class TEXT,
        therapeutic_class TEXT,
        habit_forming TEXT
    )
    """)

    cursor.execute("CREATE INDEX idx_medicines_name ON medicines(name)")

    # 3. Read updated_indian_medicine_data.csv and write joined records to DB
    print("DATABASE BUILDER: Merging records and inserting into SQLite...")
    
    count = 0
    with open(UPDATED_CSV_PATH, mode='r', encoding='utf-8') as f:
        reader = csv.reader(f)
        header = next(reader)
        
        batch = []
        for row in reader:
            if not row:
                continue
            try:
                med_id = int(row[0])
                name = row[1]
                price = float(row[2]) if row[2] else 0.0
                manufacturer = row[4]
                pack_size = row[6]
                generic = row[9] # salt_composition
                desc = row[10] if len(row) > 10 else ""
                side_effects = row[11] if len(row) > 11 else ""
                interactions = row[12] if len(row) > 12 else ""
                
                # Fetch joined info
                extra = dataset_info.get(med_id, {
                    'substitutes': '',
                    'chemical_class': '',
                    'habit_forming': '',
                    'therapeutic_class': ''
                })
                
                batch.append((
                    med_id, name, price, manufacturer, pack_size, generic, 
                    side_effects, interactions, desc,
                    extra['substitutes'], extra['chemical_class'], 
                    extra['therapeutic_class'], extra['habit_forming']
                ))
                count += 1
                
                if len(batch) >= 10000:
                    cursor.executemany("INSERT INTO medicines VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", batch)
                    conn.commit()
                    print(f"DATABASE BUILDER: Inserted {count} records...")
                    batch = []
            except Exception as e:
                pass

        if batch:
            cursor.executemany("INSERT INTO medicines VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", batch)
            conn.commit()

    print(f"DATABASE BUILDER: Merged database built successfully! Total: {count} records.")
    conn.close()

if __name__ == "__main__":
    build_merged_database()
