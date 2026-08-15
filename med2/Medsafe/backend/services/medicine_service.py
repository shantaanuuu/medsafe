import sqlite3
import os
import difflib

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.abspath(os.path.join(BASE_DIR, "..", "database", "medicines.db"))

def get_db_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def find_best_match(ocr_brand_name):
    """
    Search database to find the closest matching medicine brand name.
    Utilizes SQL query filters and SequenceMatcher for fuzzy correction.
    """
    if not ocr_brand_name:
        return None

    cleaned_name = ocr_brand_name.strip()
    if len(cleaned_name) < 3:
        return None

    print(f"MEDICINE_SERVICE: Looking up '{cleaned_name}' in SQLite database...")
    
    conn = get_db_connection()
    cursor = conn.cursor()

    # Strategy 1: Attempt exact case-insensitive match
    cursor.execute("SELECT * FROM medicines WHERE name = ? COLLATE NOCASE", (cleaned_name,))
    row = cursor.fetchone()
    if row:
        conn.close()
        print("MEDICINE_SERVICE: Exact match found!")
        return dict(row)

    # Strategy 2: Grab candidates starting with same prefix to perform fuzzy comparison
    prefix = cleaned_name[:3] + "%"
    cursor.execute("SELECT * FROM medicines WHERE name LIKE ? LIMIT 500", (prefix,))
    candidates = cursor.fetchall()

    best_match = None
    highest_score = 0.0

    for candidate in candidates:
        candidate_name = candidate['name']
        score = difflib.SequenceMatcher(None, cleaned_name.lower(), candidate_name.lower()).ratio()
        
        if score > highest_score:
            highest_score = score
            best_match = candidate

    conn.close()

    if highest_score >= 0.60 and best_match:
        print(f"MEDICINE_SERVICE: Fuzzy match found! '{best_match['name']}' with similarity score={highest_score:.2f}")
        return dict(best_match)

    print("MEDICINE_SERVICE: No confident database match found.")
    return None


def match_ocr_text_to_database(ocr_text):
    """
    Highly advanced typo-tolerant full-text matching algorithm.
    Processes raw/scrambled OCR lines, tokenizes words, generates slices (trigrams)
    for lookup, and matches candidates using SequenceMatcher.
    """
    if not ocr_text:
        return None

    # Split into raw lines
    lines = [line.strip() for line in ocr_text.split("\n") if line.strip()]
    print(f"MEDICINE_SERVICE: Advanced matching over {len(lines)} raw OCR lines...")

    conn = get_db_connection()
    cursor = conn.cursor()

    best_match = None
    highest_score = 0.0

    # Stopwords and scrap data vocabulary to ignore
    blacklist = {
        'rx', 'warning', 'exp', 'mfg', 'batch', 'b.no', 'mrp', 'rs', 'tablet', 'tablets',
        'capsule', 'capsules', 'mg', 'ml', 'only', 'mfd', 'date', 'store', 'keep', 'out',
        'of', 'reach', 'children', 'dosage', 'directed', 'by', 'physician', 'prescription',
        'schedule', 'h1', 'warning', 'drug', 'caution', 'not', 'to', 'be', 'sold'
    }

    for line in lines:
        cleaned_line = line.lower().strip()
        # Remove noisy symbols
        for char in ['®', '™', '*', '+', ':', ',', '.', '/', '-']:
            cleaned_line = cleaned_line.replace(char, ' ')
        
        cleaned_line = " ".join(cleaned_line.split()).strip()
        if len(cleaned_line) < 3:
            continue
            
        words = cleaned_line.split()
        valid_words = [w for w in words if len(w) >= 3 and w not in blacklist]
        
        if not valid_words:
            continue

        # Collect candidate rows from SQLite using token and sub-slice matches
        candidates = []
        
        # 1. Search by words
        for word in valid_words:
            # Query names containing this word (handles middle-of-string matching)
            cursor.execute("SELECT * FROM medicines WHERE name LIKE ? LIMIT 100", (f"%{word}%",))
            candidates.extend(cursor.fetchall())
            
            # 2. Slice matching for typo tolerance (e.g. "augment1n" -> "augm", "ment")
            if len(word) >= 5:
                for i in range(len(word) - 3):
                    slice_str = word[i:i+4]
                    # Only search slice if not numerical and not blacklisted
                    if slice_str not in blacklist and not slice_str.isdigit():
                        cursor.execute("SELECT * FROM medicines WHERE name LIKE ? LIMIT 50", (f"%{slice_str}%",))
                        candidates.extend(cursor.fetchall())

        # Deduplicate candidates by database ID in memory
        unique_candidates = {}
        for cand in candidates:
            unique_candidates[cand['id']] = cand

        # Score candidates
        for cand in unique_candidates.values():
            cand_name = cand['name'].lower()
            
            # Sequence similarity ratio
            score = difflib.SequenceMatcher(None, cleaned_line, cand_name).ratio()
            
            # Substring coverage boost: if a valid word matches part of the DB entry, boost score
            for w in valid_words:
                if w in cand_name:
                    coverage = len(w) / len(cand_name)
                    score = max(score, 0.45 + (coverage * 0.45))

            if score > highest_score:
                highest_score = score
                best_match = cand

    conn.close()

    # Confident threshold (50% similarity is extremely safe here due to deduplicated matching)
    if highest_score >= 0.50 and best_match:
        print(f"MEDICINE_SERVICE: Confident advanced match found! '{best_match['name']}' score={highest_score:.2f}")
        return dict(best_match)

    print("MEDICINE_SERVICE: No confident full text match found in raw OCR lines.")
    return None
