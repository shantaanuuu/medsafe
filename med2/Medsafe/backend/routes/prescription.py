import os
import uuid
from flask import Blueprint, jsonify, request
from config import UPLOAD_FOLDER
from services.gemini_service import extract_prescription_with_gemini
from services.medicine_service import find_best_match

prescription_bp = Blueprint("prescription", __name__)

@prescription_bp.route("/api/prescriptions/scan", methods=["POST"])
def scan_prescription():
    file = request.files.get("image")
    if not file or not file.filename:
        return jsonify({"status": "error", "message": "Prescription image is required."}), 400
    ext = file.filename.rsplit(".", 1)[-1].lower() if "." in file.filename else "jpg"
    path = os.path.join(UPLOAD_FOLDER, f"rx_{uuid.uuid4().hex}.{ext}")
    try:
        file.save(path)
        extracted = extract_prescription_with_gemini(path)
        medicines = []
        for item in extracted.get("medicines", []):
            name = str(item.get("name") or "").strip()
            if not name: continue
            match = find_best_match(name)
            result = {"prescription_name": name, "strength": str(item.get("strength") or ""), "instructions": str(item.get("instructions") or ""), "duration": str(item.get("duration") or ""), "dosage_schedule": str(item.get("instructions") or "")}
            if match:
                result.update({"id": str(match["id"]), "brand_name": match["name"], "generic_name": match["generic_name"], "price": match["price"], "manufacturer": match["manufacturer_name"], "side_effects": match["side_effects"], "drug_interactions": match["drug_interactions"]})
            else:
                result.update({"brand_name": name, "generic_name": ""})
            medicines.append(result)
        return jsonify({"status": "success", "data": {"medicines": medicines, "notes": str(extracted.get("notes") or "")}})
    except Exception as error:
        return jsonify({"status": "error", "message": str(error)}), 500
    finally:
        if os.path.exists(path): os.remove(path)
