import os, uuid
from flask import Blueprint, request, jsonify
from pypdf import PdfReader
from config import UPLOAD_FOLDER
from services.gemini_service import analyse_report_with_gemini

report_analysis_bp = Blueprint("report_analysis", __name__)
@report_analysis_bp.route("/api/reports/analyse", methods=["POST"])
def analyse_report():
    file = request.files.get("report")
    if not file or not file.filename.lower().endswith(".pdf"): return jsonify({"status":"error","message":"Upload a PDF report."}),400
    path=os.path.join(UPLOAD_FOLDER, f"report_{uuid.uuid4().hex}.pdf")
    try:
        file.save(path)
        text="\n".join(page.extract_text() or "" for page in PdfReader(path).pages).strip()
        if len(text)<30: return jsonify({"status":"error","message":"This PDF has no readable text. Upload a text-based report PDF."}),422
        analysis=analyse_report_with_gemini(text)
        return jsonify({"status":"success","data":{"analysis":analysis,"extracted_pages":len(PdfReader(path).pages)}})
    except Exception as error: return jsonify({"status":"error","message":str(error)}),500
    finally:
        if os.path.exists(path): os.remove(path)
