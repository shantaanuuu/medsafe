"""Allergy history, reaction triage and cabinet conflict endpoints."""

import json
import os
import re
import sqlite3
import uuid
from datetime import datetime, timezone

from flask import Blueprint, jsonify, request
from services.gemini_service import analyze_allergy_with_gemini, check_medicine_allergy_with_gemini

allergy_bp = Blueprint("allergy", __name__)
DB_PATH = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "database", "medicines.db"))

def _connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_allergy_tables():
    conn = _connection()
    conn.execute("""CREATE TABLE IF NOT EXISTS allergy_records (
        id TEXT PRIMARY KEY, user_uid TEXT NOT NULL, trigger_name TEXT NOT NULL,
        reactions TEXT NOT NULL, severity TEXT NOT NULL, notes TEXT, created_at TEXT NOT NULL
    )""")
    conn.execute("CREATE INDEX IF NOT EXISTS idx_allergy_records_user ON allergy_records(user_uid)")
    conn.commit()
    conn.close()

def _emergency_reason(text):
    value = text.lower()
    patterns = [
        r"\b(can't|cannot|cant|difficulty|trouble)\s+(to )?breathe\b", r"\bsaans\s+(nahi|nahin|lene mein dikkat|ki dikkat)\b",
        r"\b(lip|lips|tongue|face|throat|honth|jeebh|chehra|gala)\s+(swelling|swollen|suj|sujan)\b", r"\b(faint|fainted|unconscious|behosh|passed out)\b",
    ]
    return "Severe reaction symptoms detected" if any(re.search(pattern, value) for pattern in patterns) else None

@allergy_bp.route("/api/allergies", methods=["GET"])
def list_allergies():
    uid = request.args.get("uid")
    if not uid:
        return jsonify({"status": "error", "message": "uid is required"}), 400
    conn = _connection()
    rows = conn.execute("SELECT * FROM allergy_records WHERE user_uid = ? ORDER BY created_at DESC", (uid,)).fetchall()
    conn.close()
    return jsonify({"status": "success", "data": [{**dict(row), "reactions": json.loads(row["reactions"])} for row in rows]})

@allergy_bp.route("/api/allergies", methods=["POST"])
def save_allergy():
    data = request.get_json(silent=True) or {}
    uid = data.get("user_uid")
    trigger = str(data.get("trigger_name", "")).strip()
    reactions = data.get("reactions", [])
    if not uid or not trigger or not isinstance(reactions, list):
        return jsonify({"status": "error", "message": "user_uid, trigger_name and reactions are required"}), 400
    record = {"id": str(uuid.uuid4()), "user_uid": uid, "trigger_name": trigger, "reactions": [str(x) for x in reactions[:10]], "severity": str(data.get("severity", "unknown")), "notes": str(data.get("notes", ""))[:500], "created_at": datetime.now(timezone.utc).isoformat()}
    conn = _connection()
    conn.execute("INSERT INTO allergy_records (id, user_uid, trigger_name, reactions, severity, notes, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)", (record["id"], uid, trigger, json.dumps(record["reactions"]), record["severity"], record["notes"], record["created_at"]))
    conn.commit()
    conn.close()
    return jsonify({"status": "success", "data": record}), 201

@allergy_bp.route("/api/allergies/<record_id>", methods=["DELETE"])
def delete_allergy(record_id):
    uid = request.args.get("uid")
    if not uid:
        return jsonify({"status": "error", "message": "uid is required"}), 400
    conn = _connection()
    conn.execute("DELETE FROM allergy_records WHERE id = ? AND user_uid = ?", (record_id, uid))
    conn.commit()
    conn.close()
    return jsonify({"status": "success"})

@allergy_bp.route("/api/allergies/analyze", methods=["POST"])
def analyze_allergy():
    description = str((request.get_json(silent=True) or {}).get("description", "")).strip()
    if not description or len(description) > 1500:
        return jsonify({"status": "error", "message": "Enter a valid reaction description"}), 400
    emergency_reason = _emergency_reason(description)
    try:
        result = analyze_allergy_with_gemini(description)
    except RuntimeError as error:
        return jsonify({"status": "error", "message": str(error)}), 503
    result["emergency"] = emergency_reason is not None or result.get("emergency") is True
    result["emergency_reason"] = emergency_reason or result.get("emergency_reason")
    result["disclaimer"] = "Clinical Immunological Triage Assessment. Not a definitive allergy hypersensitivity diagnosis. Discontinue suspected allergen and consult a clinician."
    return jsonify({"status": "success", "data": result})

@allergy_bp.route("/api/allergies/check-medicine", methods=["POST"])
def check_medicine():
    data = request.get_json(silent=True) or {}
    allergies = data.get("allergies", [])
    medicine_name = str(data.get("medicine_name", "")).strip()
    generic_name = str(data.get("generic_name", "")).strip()
    if not isinstance(allergies, list) or not medicine_name:
        return jsonify({"status": "error", "message": "allergies and medicine_name are required"}), 400
    if not allergies:
        return jsonify({"status": "success", "data": {"potential_conflict": False, "matched_allergies": [], "message": "No saved allergies to check."}})
    try:
        result = check_medicine_allergy_with_gemini(allergies, medicine_name, generic_name)
    except RuntimeError as error:
        return jsonify({"status": "error", "message": str(error)}), 503
    return jsonify({"status": "success", "data": result})
