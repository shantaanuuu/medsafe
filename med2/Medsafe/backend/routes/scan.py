import os
import uuid
from flask import Blueprint, request, jsonify
from services.info_extractor import extract_information
from config import UPLOAD_FOLDER

scan_bp = Blueprint("scan", __name__)

@scan_bp.route("/scan", methods=["POST"])
def scan():
    try:
        ocr_text = ""
        image_path = None
        gemini_result = None
        db_match = None

        # Check if the client uploaded an image file (from scanImage)
        if 'image' in request.files:
            file = request.files['image']
            if file.filename != '':
                # Generate unique filename to avoid collision
                ext = file.filename.rsplit('.', 1)[-1].lower() if '.' in file.filename else 'png'
                filename = f"{uuid.uuid4().hex}.{ext}"
                image_path = os.path.join(UPLOAD_FOLDER, filename)
                file.save(image_path)
                print(f"routes/scan: Saved uploaded scan image to {image_path}")
                
                # Step 1: Call Gemini Vision on the image directly
                try:
                    from services.gemini_service import clean_image_with_gemini
                    gemini_result = clean_image_with_gemini(image_path)
                except Exception as e:
                    print(f"routes/scan: Gemini Vision exception: {e}")
        else:
            # Fallback to JSON payload
            data = request.get_json()
            if data and "ocr_text" in data:
                ocr_text = data["ocr_text"]
                # Step 1: Call Gemini Text API
                try:
                    from services.gemini_service import clean_ocr_with_gemini
                    gemini_result = clean_ocr_with_gemini(ocr_text)
                except Exception as e:
                    print(f"routes/scan: Gemini Text exception: {e}")

        result = {}
        if gemini_result and gemini_result.get("brand_name"):
            result["brand_name"] = gemini_result["brand_name"]
            result["expiry_date"] = gemini_result.get("expiry_date")
            result["batch_number"] = gemini_result.get("batch_number")
            result["price"] = gemini_result.get("mrp")
            
            try:
                from services.medicine_service import find_best_match
                db_match = find_best_match(gemini_result["brand_name"])
            except Exception as e:
                print(f"DATABASE LOOKUP FOR GEMINI RESULT ERROR: {e}")
        
        # Step 2: Fallback to local regex + line-by-line advanced database search if Gemini missed
        if not db_match:
            print("routes/scan: Falling back to local Regex & Advanced SQL matching...")
            if ocr_text:
                local_extracted = extract_information(ocr_text)
                if not result.get("expiry_date"):
                    result["expiry_date"] = local_extracted.get("expiry_date")
                if not result.get("batch_number"):
                    result["batch_number"] = local_extracted.get("batch_number")
                
                try:
                    from services.medicine_service import match_ocr_text_to_database
                    db_match = match_ocr_text_to_database(ocr_text)
                except Exception as e:
                    print(f"DATABASE LINE LOOKUP ERROR: {e}")
                    
                if not db_match and local_extracted.get("brand_name"):
                    try:
                        from services.medicine_service import find_best_match
                        db_match = find_best_match(local_extracted["brand_name"])
                    except Exception as e:
                        print(f"DATABASE BACKUP LOOKUP ERROR: {e}")

        # Step 3: Populate SQLite database metadata if matched
        if db_match:
            result["brand_name"] = db_match["name"]
            result["generic_name"] = db_match["generic_name"]
            result["price"] = db_match["price"]
            result["manufacturer"] = db_match["manufacturer_name"]
            result["pack_size"] = db_match["pack_size_label"]
            result["side_effects"] = db_match["side_effects"]
            result["drug_interactions"] = db_match["drug_interactions"]
            result["medicine_desc"] = db_match["medicine_desc"]
            result["substitutes"] = db_match["substitutes"]
            result["chemical_class"] = db_match["chemical_class"]
            result["therapeutic_class"] = db_match["therapeutic_class"]
            result["habit_forming"] = db_match["habit_forming"]

        # Clean up temporary uploaded image file
        if image_path and os.path.exists(image_path):
            try:
                os.remove(image_path)
                print("routes/scan: Temporary image cleaned up.")
            except Exception as e:
                print(f"routes/scan: Error removing temporary image: {e}")

        return jsonify({
            "status": "success",
            "received_text": ocr_text,
            "data": result
        })
    except Exception as e:
        print(f"routes/scan: Exception in scan: {e}")
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500