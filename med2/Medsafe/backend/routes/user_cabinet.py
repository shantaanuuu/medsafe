import sqlite3
import os
from flask import Blueprint, request, jsonify

user_cabinet_bp = Blueprint("user_cabinet", __name__)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.abspath(os.path.join(BASE_DIR, "..", "database", "medicines.db"))

def get_db_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.execute("PRAGMA foreign_keys = ON")
    conn.row_factory = sqlite3.Row
    return conn

def init_user_tables():
    """Create tables for user profiles and user cabinets inside medicines.db if they do not exist."""
    print("USER_CABINET: Initializing SQLite User tables...")
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # 1. Users table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS users (
        uid TEXT PRIMARY KEY,
        email TEXT,
        role TEXT,
        username TEXT,
        created_at TEXT
    )
    """)
    
    # 2. User Medicines (cabinet inventory) table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS user_medicines (
        id TEXT PRIMARY KEY,
        user_uid TEXT,
        name TEXT,
        generic_name TEXT,
        barcode TEXT,
        batch_number TEXT,
        expiry_date TEXT,
        added_date TEXT,
        dosage_form TEXT,
        verified_source INTEGER,
        price REAL,
        manufacturer TEXT,
        side_effects TEXT,
        drug_interactions TEXT,
        medicine_desc TEXT,
        substitutes TEXT,
        chemical_class TEXT,
        therapeutic_class TEXT,
        habit_forming TEXT,
        nickname TEXT,
        quantity REAL,
        dosage_schedule TEXT,
        FOREIGN KEY(user_uid) REFERENCES users(uid)
    )
    """)

    # 3. User Health Profiles table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS user_health_profiles (
        id TEXT PRIMARY KEY,
        firebase_uid TEXT UNIQUE,
        role TEXT CHECK(role IN ('Patient', 'Caregiver')),
        age INTEGER,
        weight_kg REAL,
        sex TEXT,
        chronic_conditions TEXT,
        current_medications TEXT,
        allergies TEXT,
        onboarding_step INTEGER,
        onboarding_completed BOOLEAN,
        created_at TEXT,
        updated_at TEXT,
        nickname TEXT,
        FOREIGN KEY(firebase_uid) REFERENCES users(uid)
    )
    """)
    # 4. Dependents table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS dependents (
        id TEXT PRIMARY KEY,
        caregiver_uid TEXT,
        name TEXT,
        nickname TEXT,
        chronic_conditions TEXT,
        current_medications TEXT,
        allergies TEXT,
        age INTEGER,
        weight_kg REAL,
        sex TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY(caregiver_uid) REFERENCES users(uid)
    )
    """)

    # 5. Medication Schedules table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS medication_schedules (
        id TEXT PRIMARY KEY,
        cabinet_item_id TEXT NOT NULL,
        dependent_id TEXT,
        user_uid TEXT NOT NULL,
        frequency_per_day INTEGER NOT NULL,
        scheduled_times TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(cabinet_item_id) REFERENCES user_medicines(id) ON DELETE CASCADE,
        FOREIGN KEY(user_uid) REFERENCES users(uid) ON DELETE CASCADE
    )
    """)
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_medication_schedules_cabinet_item ON medication_schedules(cabinet_item_id)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_medication_schedules_user ON medication_schedules(user_uid)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_medication_schedules_dependent ON medication_schedules(dependent_id)")

    # 6. Medication Logs table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS medication_logs (
        id TEXT PRIMARY KEY,
        cabinet_item_id TEXT NOT NULL,
        dependent_id TEXT,
        user_uid TEXT NOT NULL,
        dose_time TEXT NOT NULL,
        taken_date TEXT NOT NULL,
        taken INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY(cabinet_item_id) REFERENCES user_medicines(id) ON DELETE CASCADE,
        FOREIGN KEY(user_uid) REFERENCES users(uid) ON DELETE CASCADE,
        UNIQUE(cabinet_item_id, dose_time, taken_date)
    )
    """)
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_medication_logs_cabinet_item ON medication_logs(cabinet_item_id)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_medication_logs_user ON medication_logs(user_uid)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_medication_logs_date ON medication_logs(taken_date)")

    conn.commit()

    # Dynamic migrations
    cursor.execute("PRAGMA table_info(user_medicines)")
    med_cols = [col[1] for col in cursor.fetchall()]
    if "nickname" not in med_cols:
        cursor.execute("ALTER TABLE user_medicines ADD COLUMN nickname TEXT")
    if "quantity" not in med_cols:
        cursor.execute("ALTER TABLE user_medicines ADD COLUMN quantity REAL")
    if "dosage_schedule" not in med_cols:
        cursor.execute("ALTER TABLE user_medicines ADD COLUMN dosage_schedule TEXT")
    if "dependent_id" not in med_cols:
        cursor.execute("ALTER TABLE user_medicines ADD COLUMN dependent_id TEXT")

    cursor.execute("PRAGMA table_info(user_health_profiles)")
    profile_cols = [col[1] for col in cursor.fetchall()]
    if "nickname" not in profile_cols:
        cursor.execute("ALTER TABLE user_health_profiles ADD COLUMN nickname TEXT")

    conn.commit()
    conn.close()
    print("USER_CABINET: User tables ready.")

# Initialize tables immediately upon module loading
init_user_tables()

# =====================================================
# API Endpoints
# =====================================================

@user_cabinet_bp.route("/api/user/sync", methods=["POST"])
def sync_user():
    """Create or update user profile details in SQLite."""
    data = request.get_json()
    if not data or "uid" not in data:
        return jsonify({"status": "error", "message": "uid is required"}), 400

    uid = data["uid"]
    email = data.get("email", "")
    role = data.get("role", "Patient")
    username = data.get("username", "")

    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
        INSERT INTO users (uid, email, role, username, created_at)
        VALUES (?, ?, ?, ?, datetime('now'))
        ON CONFLICT(uid) DO UPDATE SET
            email=excluded.email,
            role=excluded.role,
            username=excluded.username
        """, (uid, email, role, username))
        conn.commit()
        conn.close()
        return jsonify({"status": "success", "message": "User profile synchronized successfully"})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@user_cabinet_bp.route("/api/cabinet", methods=["GET"])
def get_cabinet():
    """Retrieve the user's medicine cabinet inventory."""
    uid = request.args.get("uid")
    dependent_id = request.args.get("dependent_id")
    if not uid:
        return jsonify({"status": "error", "message": "uid parameter is required"}), 400

    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        if dependent_id:
            cursor.execute("SELECT * FROM user_medicines WHERE user_uid = ? AND dependent_id = ?", (uid, dependent_id))
        else:
            cursor.execute("SELECT * FROM user_medicines WHERE user_uid = ? AND dependent_id IS NULL", (uid,))
        rows = cursor.fetchall()
        
        cabinet = []
        for row in rows:
            cabinet.append(dict(row))
            
        conn.close()
        return jsonify({"status": "success", "data": cabinet})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@user_cabinet_bp.route("/api/cabinet", methods=["POST"])
def add_to_cabinet():
    """Add or update a medicine in the user's cabinet."""
    data = request.get_json()
    if not data or "uid" not in data or "medicine" not in data:
        return jsonify({"status": "error", "message": "uid and medicine details are required"}), 400

    uid = data["uid"]
    med = data["medicine"]

    med_id = med.get("id")
    if not med_id:
        return jsonify({"status": "error", "message": "medicine id is required"}), 400

    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("SELECT id FROM user_medicines WHERE id = ?", (med_id,))
        exists = cursor.fetchone()
        
        if exists:
            cursor.execute("""
            UPDATE user_medicines SET
                name=?, generic_name=?, barcode=?, batch_number=?, expiry_date=?, added_date=?, dosage_form=?, verified_source=?,
                price=?, manufacturer=?, side_effects=?, drug_interactions=?, medicine_desc=?, substitutes=?, chemical_class=?, therapeutic_class=?, habit_forming=?,
                nickname=?, quantity=?, dosage_schedule=?, dependent_id=?
            WHERE id=? AND user_uid=?
            """, (
                med.get("name"), med.get("genericName"), med.get("barcode"), med.get("batchNumber"),
                med.get("expiryDate"), med.get("addedDate"), med.get("dosageForm"), med.get("verifiedSource"),
                med.get("price"), med.get("manufacturer"), med.get("sideEffects"), med.get("drugInteractions"),
                med.get("medicineDesc"), med.get("substitutes"), med.get("chemicalClass"), med.get("therapeuticClass"), med.get("habitForming"),
                med.get("nickname"), med.get("quantity"), med.get("dosageSchedule"), med.get("dependent_id") or med.get("dependentId"),
                med_id, uid
            ))
        else:
            cursor.execute("""
            INSERT INTO user_medicines (
                id, user_uid, name, generic_name, barcode, batch_number, expiry_date, added_date, dosage_form, verified_source,
                price, manufacturer, side_effects, drug_interactions, medicine_desc, substitutes, chemical_class, therapeutic_class, habit_forming,
                nickname, quantity, dosage_schedule, dependent_id
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                med_id, uid, med.get("name"), med.get("genericName"), med.get("barcode"), med.get("batchNumber"),
                med.get("expiryDate"), med.get("addedDate"), med.get("dosageForm"), med.get("verifiedSource"),
                med.get("price"), med.get("manufacturer"), med.get("sideEffects"), med.get("drugInteractions"),
                med.get("medicineDesc"), med.get("substitutes"), med.get("chemicalClass"), med.get("therapeuticClass"), med.get("habitForming"),
                med.get("nickname"), med.get("quantity"), med.get("dosageSchedule"), med.get("dependent_id") or med.get("dependentId")
            ))
            
        conn.commit()
        conn.close()
        return jsonify({"status": "success", "message": "Medicine added/updated in database cabinet"})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@user_cabinet_bp.route("/api/cabinet/<med_id>", methods=["DELETE"])
def remove_from_cabinet(med_id):
    """Delete a medicine from the user's cabinet."""
    uid = request.args.get("uid")
    dependent_id = request.args.get("dependent_id")
    if not uid:
        return jsonify({"status": "error", "message": "uid parameter is required"}), 400

    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        if dependent_id:
            cursor.execute("DELETE FROM user_medicines WHERE id = ? AND user_uid = ? AND dependent_id = ?", (med_id, uid, dependent_id))
        else:
            cursor.execute("DELETE FROM user_medicines WHERE id = ? AND user_uid = ? AND dependent_id IS NULL", (med_id, uid))
        conn.commit()
        conn.close()
        return jsonify({"status": "success", "message": "Medicine removed from database cabinet"})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@user_cabinet_bp.route("/api/user/profile", methods=["GET"])
def get_profile():
    uid = request.args.get("uid")
    if not uid:
        return jsonify({"status": "error", "message": "uid parameter is required"}), 400
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM user_health_profiles WHERE firebase_uid = ?", (uid,))
        row = cursor.fetchone()
        conn.close()
        
        if not row:
            return jsonify({"status": "error", "message": "Profile not found"}), 404
            
        import json
        return jsonify({
            "status": "success",
            "data": {
                "id": row["id"],
                "firebase_uid": row["firebase_uid"],
                "role": row["role"],
                "age": row["age"],
                "weight_kg": row["weight_kg"],
                "sex": row["sex"],
                "chronic_conditions": json.loads(row["chronic_conditions"]) if row["chronic_conditions"] else [],
                "current_medications": json.loads(row["current_medications"]) if row["current_medications"] else [],
                "allergies": json.loads(row["allergies"]) if row["allergies"] else [],
                "onboarding_step": row["onboarding_step"],
                "onboarding_completed": bool(row["onboarding_completed"]),
                "created_at": row["created_at"],
                "updated_at": row["updated_at"],
                "nickname": row["nickname"]
            }
        })
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@user_cabinet_bp.route("/api/user/profile/create", methods=["POST"])
def create_profile():
    data = request.get_json()
    if not data or "firebase_uid" not in data:
        return jsonify({"status": "error", "message": "firebase_uid is required"}), 400
        
    uid = data["firebase_uid"]
    import uuid
    import datetime
    profile_id = str(uuid.uuid4())
    now_str = datetime.datetime.utcnow().isoformat()
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Check if already exists
        cursor.execute("SELECT id FROM user_health_profiles WHERE firebase_uid = ?", (uid,))
        existing = cursor.fetchone()
        if existing:
            conn.close()
            return jsonify({"status": "success", "message": "Profile already exists", "data": {"id": existing["id"]}})
            
        # Ensure user exists in users table or insert dummy
        cursor.execute("SELECT uid FROM users WHERE uid = ?", (uid,))
        user_row = cursor.fetchone()
        if not user_row:
            cursor.execute(
                "INSERT INTO users (uid, email, role, username, created_at) VALUES (?, ?, ?, ?, ?)",
                (uid, data.get("email", ""), "Patient", data.get("username", ""), now_str)
            )
            
        cursor.execute("""
        INSERT INTO user_health_profiles (
            id, firebase_uid, role, age, weight_kg, sex, chronic_conditions, current_medications, allergies,
            onboarding_step, onboarding_completed, created_at, updated_at, nickname
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            profile_id, uid, "Patient", None, None, None, "[]", "[]", "[]", 1, False, now_str, now_str, None
        ))
        conn.commit()
        conn.close()
        
        return jsonify({
            "status": "success",
            "data": {
                "id": profile_id,
                "firebase_uid": uid,
                "role": "Patient",
                "age": None,
                "weight_kg": None,
                "sex": None,
                "chronic_conditions": [],
                "current_medications": [],
                "allergies": [],
                "onboarding_step": 1,
                "onboarding_completed": False,
                "created_at": now_str,
                "updated_at": now_str,
                "nickname": None
            }
        })
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@user_cabinet_bp.route("/api/user/profile/update", methods=["POST"])
def update_profile():
    data = request.get_json()
    if not data or "firebase_uid" not in data:
        return jsonify({"status": "error", "message": "firebase_uid is required"}), 400
        
    uid = data["firebase_uid"]
    import json
    import datetime
    now_str = datetime.datetime.utcnow().isoformat()
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Fetch current profile to merge
        cursor.execute("SELECT * FROM user_health_profiles WHERE firebase_uid = ?", (uid,))
        row = cursor.fetchone()
        if not row:
            conn.close()
            return jsonify({"status": "error", "message": "Profile not found"}), 404
            
        role = data.get("role", row["role"])
        age = data.get("age", row["age"])
        weight_kg = data.get("weight_kg", row["weight_kg"])
        sex = data.get("sex", row["sex"])
        nickname = data.get("nickname", row["nickname"])
        
        chronic_conditions = row["chronic_conditions"]
        if "chronic_conditions" in data:
            chronic_conditions = json.dumps(data["chronic_conditions"])
            
        current_medications = row["current_medications"]
        if "current_medications" in data:
            current_medications = json.dumps(data["current_medications"])
            
        allergies = row["allergies"]
        if "allergies" in data:
            allergies = json.dumps(data["allergies"])
            
        onboarding_step = data.get("onboarding_step", row["onboarding_step"])
        onboarding_completed = int(data.get("onboarding_completed", row["onboarding_completed"]))
        
        cursor.execute("""
        UPDATE user_health_profiles SET
            role = ?, age = ?, weight_kg = ?, sex = ?, chronic_conditions = ?, current_medications = ?,
            allergies = ?, onboarding_step = ?, onboarding_completed = ?, updated_at = ?, nickname = ?
        WHERE firebase_uid = ?
        """, (
            role, age, weight_kg, sex, chronic_conditions, current_medications, allergies,
            onboarding_step, onboarding_completed, now_str, nickname, uid
        ))
        
        # Check if onboarding was completed in this request
        if onboarding_completed == 1 and not row["onboarding_completed"]:
            import uuid
            current_meds_list = []
            if "current_medications" in data:
                current_meds_list = data["current_medications"]
            elif row["current_medications"]:
                current_meds_list = json.loads(row["current_medications"])
                
            for med_entry in current_meds_list:
                med_id = med_entry.get("medicine_id") or med_entry.get("medicineId")
                if med_id:
                    cursor.execute("SELECT * FROM medicines WHERE id = ?", (med_id,))
                    med_row = cursor.fetchone()
                    if med_row:
                        user_med_id = str(uuid.uuid4())
                        cursor.execute("""
                        INSERT INTO user_medicines (
                            id, user_uid, name, generic_name, barcode, batch_number, expiry_date, added_date,
                            dosage_form, verified_source, price, manufacturer, side_effects, drug_interactions,
                            medicine_desc, substitutes, chemical_class, therapeutic_class, habit_forming
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                        """, (
                            user_med_id, uid, med_row["name"], med_row["generic_name"], "", "BATCH-ONBOARD",
                            datetime.datetime.now().strftime("%Y-%m-%d"), datetime.datetime.now().strftime("%Y-%m-%d"),
                            "Tablet", 2, med_row["price"], med_row["manufacturer_name"], med_row["side_effects"],
                            med_row["drug_interactions"], "", med_row["substitutes"], med_row["chemical_class"],
                            med_row["therapeutic_class"], med_row["habit_forming"]
                        ))
        
        # Sync user role back to primary users table
        cursor.execute("UPDATE users SET role = ? WHERE uid = ?", (role, uid))
        
        conn.commit()
        conn.close()
        return jsonify({"status": "success", "message": "Profile updated successfully"})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@user_cabinet_bp.route("/api/dependents", methods=["GET"])
def get_dependents():
    caregiver_uid = request.args.get("caregiver_uid")
    if not caregiver_uid:
        return jsonify({"status": "error", "message": "caregiver_uid parameter is required"}), 400

    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM dependents WHERE caregiver_uid = ?", (caregiver_uid,))
        rows = cursor.fetchall()
        
        import json
        dependents = []
        for r in rows:
            dependents.append({
                "id": r["id"],
                "firebase_uid": r["caregiver_uid"],
                "role": "Patient",
                "name": r["name"],
                "nickname": r["nickname"],
                "chronic_conditions": json.loads(r["chronic_conditions"]) if r["chronic_conditions"] else [],
                "current_medications": json.loads(r["current_medications"]) if r["current_medications"] else [],
                "allergies": json.loads(r["allergies"]) if r["allergies"] else [],
                "age": r["age"],
                "weight_kg": r["weight_kg"],
                "sex": r["sex"],
                "onboarding_step": 3,
                "onboarding_completed": True,
                "created_at": r["created_at"],
                "updated_at": r["updated_at"]
            })
            
        conn.close()
        return jsonify({"status": "success", "data": dependents})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@user_cabinet_bp.route("/api/dependents", methods=["POST"])
def save_dependent():
    data = request.get_json()
    if not data or "id" not in data or "firebase_uid" not in data:
        return jsonify({"status": "error", "message": "id and firebase_uid (caregiver) are required"}), 400

    dep_id = data["id"]
    caregiver_uid = data["firebase_uid"]
    name = data.get("nickname") or data.get("name") or "Dependent"
    nickname = data.get("nickname")
    age = data.get("age")
    weight_kg = data.get("weight_kg")
    sex = data.get("sex")
    
    import json
    import datetime
    now_str = datetime.datetime.utcnow().isoformat()
    
    chronic_conditions = json.dumps(data.get("chronic_conditions", []))
    current_medications = json.dumps(data.get("current_medications", []))
    allergies = json.dumps(data.get("allergies", []))

    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
        INSERT INTO dependents (
            id, caregiver_uid, name, nickname, chronic_conditions, current_medications, allergies,
            age, weight_kg, sex, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
            name=excluded.name,
            nickname=excluded.nickname,
            chronic_conditions=excluded.chronic_conditions,
            current_medications=excluded.current_medications,
            allergies=excluded.allergies,
            age=excluded.age,
            weight_kg=excluded.weight_kg,
            sex=excluded.sex,
            updated_at=excluded.updated_at
        """, (
            dep_id, caregiver_uid, name, nickname, chronic_conditions, current_medications, allergies,
            age, weight_kg, sex, now_str, now_str
        ))
        
        current_meds_list = data.get("current_medications", [])
        import uuid
        for med_entry in current_meds_list:
            med_id = med_entry.get("medicine_id") or med_entry.get("medicineId")
            if med_id:
                cursor.execute("SELECT id FROM user_medicines WHERE user_uid = ? AND dependent_id = ? AND name = (SELECT name FROM medicines WHERE id = ?)", (caregiver_uid, dep_id, med_id))
                exists = cursor.fetchone()
                if not exists:
                    cursor.execute("SELECT * FROM medicines WHERE id = ?", (med_id,))
                    med_row = cursor.fetchone()
                    if med_row:
                        user_med_id = str(uuid.uuid4())
                        cursor.execute("""
                        INSERT INTO user_medicines (
                            id, user_uid, name, generic_name, barcode, batch_number, expiry_date, added_date,
                            dosage_form, verified_source, price, manufacturer, side_effects, drug_interactions,
                            medicine_desc, substitutes, chemical_class, therapeutic_class, habit_forming, dependent_id
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                        """, (
                            user_med_id, caregiver_uid, med_row["name"], med_row["generic_name"], "", "BATCH-ONBOARD",
                            datetime.datetime.now().strftime("%Y-%m-%d"), datetime.datetime.now().strftime("%Y-%m-%d"),
                            "Tablet", 2, med_row["price"], med_row["manufacturer_name"], med_row["side_effects"],
                            med_row["drug_interactions"], "", med_row["substitutes"], med_row["chemical_class"],
                            med_row["therapeutic_class"], med_row["habit_forming"], dep_id
                        ))
        
        conn.commit()
        conn.close()
        return jsonify({"status": "success", "message": "Dependent profile saved successfully"})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@user_cabinet_bp.route("/api/dependents/<dep_id>", methods=["DELETE"])
def delete_dependent(dep_id):
    caregiver_uid = request.args.get("caregiver_uid")
    if not caregiver_uid:
        return jsonify({"status": "error", "message": "caregiver_uid is required"}), 400

    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM dependents WHERE id = ? AND caregiver_uid = ?", (dep_id, caregiver_uid))
        cursor.execute("DELETE FROM user_medicines WHERE user_uid = ? AND dependent_id = ?", (caregiver_uid, dep_id))
        conn.commit()
        conn.close()
        return jsonify({"status": "success", "message": "Dependent profile deleted successfully"})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@user_cabinet_bp.route("/api/schedules", methods=["GET"])
def get_schedules():
    uid = request.args.get("uid")
    dependent_id = request.args.get("dependent_id")
    if not uid:
        return jsonify({"status": "error", "message": "uid parameter is required"}), 400

    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        if dependent_id and dependent_id != "null" and dependent_id != "":
            cursor.execute("SELECT * FROM medication_schedules WHERE user_uid = ? AND dependent_id = ?", (uid, dependent_id))
        else:
            cursor.execute("SELECT * FROM medication_schedules WHERE user_uid = ? AND (dependent_id IS NULL OR dependent_id = '')", (uid,))
        rows = cursor.fetchall()
        
        schedules = []
        for row in rows:
            schedule_dict = dict(row)
            import json
            try:
                schedule_dict["scheduled_times"] = json.loads(schedule_dict["scheduled_times"])
            except Exception:
                schedule_dict["scheduled_times"] = []
            schedules.append(schedule_dict)
            
        conn.close()
        return jsonify({"status": "success", "data": schedules})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@user_cabinet_bp.route("/api/schedules", methods=["POST"])
def save_schedule():
    data = request.get_json()
    if not data or "id" not in data or "cabinet_item_id" not in data or "user_uid" not in data:
        return jsonify({"status": "error", "message": "Missing required schedule fields"}), 400

    import json
    scheduled_times = data.get("scheduled_times", [])
    scheduled_times_str = json.dumps(scheduled_times)
    dep_id = data.get("dependent_id")
    if dep_id == "null" or dep_id == "":
        dep_id = None

    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
        INSERT INTO medication_schedules (
            id, cabinet_item_id, dependent_id, user_uid, frequency_per_day, scheduled_times, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
        ON CONFLICT(id) DO UPDATE SET
            frequency_per_day=excluded.frequency_per_day,
            scheduled_times=excluded.scheduled_times,
            updated_at=datetime('now')
        """, (
            data["id"], data["cabinet_item_id"], dep_id, data["user_uid"],
            data["frequency_per_day"], scheduled_times_str
        ))
        conn.commit()
        conn.close()
        return jsonify({"status": "success", "message": "Medication schedule saved successfully"})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@user_cabinet_bp.route("/api/schedules/<schedule_id>", methods=["DELETE"])
def delete_schedule(schedule_id):
    uid = request.args.get("uid")
    if not uid:
        return jsonify({"status": "error", "message": "uid parameter is required"}), 400

    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM medication_schedules WHERE id = ? AND user_uid = ?", (schedule_id, uid))
        conn.commit()
        conn.close()
        return jsonify({"status": "success", "message": "Medication schedule deleted successfully"})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@user_cabinet_bp.route("/api/logs", methods=["GET"])
def get_logs():
    uid = request.args.get("uid")
    date_str = request.args.get("date")
    dependent_id = request.args.get("dependent_id")
    if not uid or not date_str:
        return jsonify({"status": "error", "message": "uid and date parameters are required"}), 400

    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        if dependent_id and dependent_id != "null" and dependent_id != "":
            cursor.execute("SELECT * FROM medication_logs WHERE user_uid = ? AND dependent_id = ? AND taken_date = ?", (uid, dependent_id, date_str))
        else:
            cursor.execute("SELECT * FROM medication_logs WHERE user_uid = ? AND (dependent_id IS NULL OR dependent_id = '') AND taken_date = ?", (uid, date_str))
        rows = cursor.fetchall()
        
        logs = []
        for row in rows:
            log_dict = dict(row)
            log_dict["taken"] = bool(log_dict["taken"])
            logs.append(log_dict)
            
        conn.close()
        return jsonify({"status": "success", "data": logs})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@user_cabinet_bp.route("/api/logs", methods=["POST"])
def save_log():
    data = request.get_json()
    if not data or "cabinet_item_id" not in data or "user_uid" not in data or "dose_time" not in data or "taken_date" not in data:
        return jsonify({"status": "error", "message": "Missing required log fields"}), 400

    log_id = data.get("id")
    if not log_id:
        import uuid
        log_id = str(uuid.uuid4())

    dep_id = data.get("dependent_id")
    if dep_id == "null" or dep_id == "":
        dep_id = None
        
    taken_val = 1 if data.get("taken", False) else 0

    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
        INSERT INTO medication_logs (
            id, cabinet_item_id, dependent_id, user_uid, dose_time, taken_date, taken, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'))
        ON CONFLICT(cabinet_item_id, dose_time, taken_date) DO UPDATE SET
            taken=excluded.taken
        """, (
            log_id, data["cabinet_item_id"], dep_id, data["user_uid"],
            data["dose_time"], data["taken_date"], taken_val
        ))
        conn.commit()
        conn.close()
        return jsonify({"status": "success", "message": "Medication log saved successfully"})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@user_cabinet_bp.route("/api/chatbot", methods=["POST"])
def chatbot_chat():
    data = request.get_json()
    if not data or "message" not in data:
        return jsonify({"status": "error", "message": "message field is required"}), 400

    system_prompt = data.get("system_prompt", "")
    message = data.get("message", "")
    history = data.get("history", [])
    context = data.get("context", "")

    from services.gemini_service import chat_with_gemini
    reply = chat_with_gemini(system_prompt, message, history, context)
    return jsonify({"status": "success", "reply": reply})
