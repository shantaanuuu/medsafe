import sqlite3
import os
from flask import Blueprint, request, jsonify

user_cabinet_bp = Blueprint("user_cabinet", __name__)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.abspath(os.path.join(BASE_DIR, "..", "database", "medicines.db"))

def get_db_connection():
    conn = sqlite3.connect(DB_PATH)
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
        FOREIGN KEY(user_uid) REFERENCES users(uid)
    )
    """)
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
    if not uid:
        return jsonify({"status": "error", "message": "uid parameter is required"}), 400

    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM user_medicines WHERE user_uid = ?", (uid,))
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
        cursor.execute("""
        INSERT OR REPLACE INTO user_medicines (
            id, user_uid, name, generic_name, barcode, batch_number, expiry_date, added_date, dosage_form, verified_source,
            price, manufacturer, side_effects, drug_interactions, medicine_desc, substitutes, chemical_class, therapeutic_class, habit_forming
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            med_id, uid, med.get("name"), med.get("genericName"), med.get("barcode"), med.get("batchNumber"),
            med.get("expiryDate"), med.get("addedDate"), med.get("dosageForm"), med.get("verifiedSource"),
            med.get("price"), med.get("manufacturer"), med.get("sideEffects"), med.get("drugInteractions"),
            med.get("medicineDesc"), med.get("substitutes"), med.get("chemicalClass"), med.get("therapeuticClass"), med.get("habitForming")
        ))
        conn.commit()
        conn.close()
        return jsonify({"status": "success", "message": "Medicine added to database cabinet"})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@user_cabinet_bp.route("/api/cabinet/<med_id>", methods=["DELETE"])
def remove_from_cabinet(med_id):
    """Delete a medicine from the user's cabinet."""
    uid = request.args.get("uid")
    if not uid:
        return jsonify({"status": "error", "message": "uid parameter is required"}), 400

    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM user_medicines WHERE id = ? AND user_uid = ?", (med_id, uid))
        conn.commit()
        conn.close()
        return jsonify({"status": "success", "message": "Medicine removed from database cabinet"})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500
