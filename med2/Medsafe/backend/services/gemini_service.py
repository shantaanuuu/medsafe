import os
import json
import google.generativeai as genai
from PIL import Image


def analyze_allergy_with_gemini(description):
    """Perform formal clinical triage assessment for suspected allergic reaction."""
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key or api_key == "your_gemini_api_key_here":
        raise RuntimeError("Gemini is not configured. Add GEMINI_API_KEY to the backend .env file.")
    try:
        genai.configure(api_key=api_key)
        model = genai.GenerativeModel("gemini-3.5-flash")
        prompt = f'''You are an Automated Clinical Immunological Triage Model.
Evaluate this patient-reported reaction objectively and formally. Do NOT sound like a conversational chatbot, virtual assistant, or AI. Use objective clinical diagnostic triage terminology.
Report: "{description}"

Return STRICT JSON only:
{{
  "trigger": "Suspected Allergen / Agent",
  "allergen_category": "Pharmaceutical (Antibiotic / Analgesic) | Food / Dietary | Environmental | Contact | Unknown",
  "severity": "Mild (Localized) | Moderate (Dispersed) | Severe (Systemic / High Acuity)",
  "triage_level": "Level 1 - Emergency Evaluation | Level 2 - Urgent Clinical Review | Level 3 - Routine Observational",
  "reactions": ["Cutaneous Erythema / Rash", "Pruritus / Itching"],
  "summary": "Formal clinical summary of reaction pattern and physiological manifestation.",
  "guidance": [
    "Immediately withhold exposure to suspected agent",
    "Document compound and batch identification in medical record",
    "Monitor for progressive mucosal or airway compromise"
  ],
  "emergency": false
}}
Set emergency=true only if dyspnea, wheezing, angioedema (face/tongue/throat swelling), hypotension, or syncope/fainting is reported.'''
        return _parse_json_response(model.generate_content(prompt).text)
    except Exception as error:
        print(f"GEMINI_SERVICE ERROR: allergy analysis failed: {error}")
        raise RuntimeError("Could not analyse the allergy description.") from error


def check_medicine_allergy_with_gemini(allergies, medicine_name, generic_name):
    """Conservatively identify a potential, never confirmed, allergy conflict."""
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key or api_key == "your_gemini_api_key_here":
        raise RuntimeError("Gemini is not configured. Add GEMINI_API_KEY to the backend .env file.")
    try:
        genai.configure(api_key=api_key)
        model = genai.GenerativeModel("gemini-3.5-flash")
        prompt = f'''Perform conservative medicine-allergy screening only. Do not diagnose, prescribe, or say a medicine is safe.
Known allergy entries: {json.dumps(allergies)}
Medicine brand: {medicine_name}
Generic/ingredient information: {generic_name}
Return STRICT JSON only: {{"potential_conflict": false, "matched_allergies": [], "message": "short cautious explanation"}}
Set potential_conflict=true only if a listed allergy plausibly matches this medicine, its ingredient, or a closely related medicine family. When uncertain, set false.'''
        return _parse_json_response(model.generate_content(prompt).text)
    except Exception as error:
        print(f"GEMINI_SERVICE ERROR: medicine allergy check failed: {error}")
        raise RuntimeError("Could not complete the medicine allergy check.") from error


def _parse_json_response(response_text):
    """Parse Gemini JSON while tolerating an accidental Markdown fence."""
    text = response_text.strip()
    if text.startswith("```json"):
        text = text[7:]
    elif text.startswith("```"):
        text = text[3:]
    if text.endswith("```"):
        text = text[:-3]
    return json.loads(text.strip())


def analyze_symptoms_with_gemini(description, age, sex, evidence_catalog):
    """Perform structured clinical symptom triage and physiological mapping.

    Acts as an objective Clinical Decision Support triage model, NOT a conversational AI.
    Never speculates disease diagnoses.
    """
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key or api_key == "your_gemini_api_key_here":
        raise RuntimeError("Gemini is not configured. Add GEMINI_API_KEY to the backend .env file.")

    try:
        genai.configure(api_key=api_key)
        model = genai.GenerativeModel("gemini-3.5-flash")
        prompt = f"""
You are a Clinical Decision Support (CDSS) Symptom Triage Model.
Evaluate the patient intake (Age {age}, Sex {sex}) objectively and formally.
CRITICAL INSTRUCTIONS:
- Do NOT sound like a conversational AI, chatbot, or virtual assistant.
- Do NOT output speculative disease diagnoses (do NOT diagnose or suggest disease names like flu, migraine, pneumonia).
- Output an objective clinical triage evaluation: triage severity level, affected physiological systems, clinical symptom normalisation, and standardized clinical guidance protocol.

PATIENT INTAKE:
"{description}"

CATALOG CODES:
{json.dumps(evidence_catalog, ensure_ascii=False)}

Return STRICT JSON only in exactly this shape:
{{
  "triage_level": "Mild / Self-Limiting | Moderate / Outpatient Evaluation | High Acuity / Urgent Care | Critical / Emergency",
  "triage_code": "TRIAGE-CAT-1 | TRIAGE-CAT-2 | TRIAGE-CAT-3 | TRIAGE-CAT-4",
  "affected_systems": ["Upper Respiratory", "Neurological / Cephalic", "Gastrointestinal", "Systemic / Febrile", "Dermatological"],
  "matched_evidences": ["E_..."],
  "recognized_symptoms": [
    {{"user_phrase": "exact user phrase", "normalised": "Formal Clinical Term (e.g. Pyrexia / Cephalea / Tussis)"}}
  ],
  "summary": "Formal clinical triage observation statement summarizing physiological presentation.",
  "advice": [
    "Clinical protocol step 1",
    "Clinical protocol step 2",
    "Clinical protocol step 3"
  ],
  "emergency": false
}}
"""
        response = model.generate_content(prompt)
        return _parse_json_response(response.text)
    except Exception as error:
        print(f"GEMINI_SERVICE ERROR: symptom analysis failed: {error}")
        raise RuntimeError("Could not analyse the symptom description with Gemini.") from error

def clean_ocr_with_gemini(ocr_text):
    """
    Leverages Gemini LLM to extract structured, corrected medicine brand name,
    expiry date, batch number, and price from raw noisy OCR text.
    """
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key or api_key == "your_gemini_api_key_here":
        print("GEMINI_SERVICE: GEMINI_API_KEY is not configured in .env file.")
        return None

    try:
        print("GEMINI_SERVICE: Authenticating and initializing Gemini API for text cleaning...")
        genai.configure(api_key=api_key)
        # Using stable gemini-3.5-flash
        model = genai.GenerativeModel("gemini-3.5-flash")
        
        prompt = f"""
        Analyze the following raw, noisy, and potentially scrambled OCR text captured from a medicine package.
        
        ---
        {ocr_text}
        ---
        
        Your task is to identify and extract the following fields. If a field is not found or is unreadable, set its value to null:
        
        1. "brand_name": The corrected brand/product name of the medicine (e.g. "Augmentin 625 Duo Tablet", "Dolo 650", "Metformin 500mg"). Correct any obvious spelling typos caused by OCR scanning errors.
        2. "expiry_date": The expiry date of the medicine package, normalized into DD/MM/YYYY format if readable.
        3. "batch_number": The manufacturing batch number or batch code.
        4. "mrp": The printed retail price (numerical value only).
        
        Provide your output as a STRICT JSON object only. Do not include markdown code block syntax (like ```json ... ```) or any additional explanation text.
        """
        
        response = model.generate_content(prompt)
        response_text = response.text.strip()
        
        # Strip markdown syntax if returned anyway
        if response_text.startswith("```json"):
            response_text = response_text[7:]
        if response_text.endswith("```"):
            response_text = response_text[:-3]
            
        parsed_data = json.loads(response_text.strip())
        print(f"GEMINI_SERVICE: OCR text analysis complete. Parsed data: {parsed_data}")
        return parsed_data
    except Exception as e:
        print(f"GEMINI_SERVICE ERROR: Failed to call Gemini Text API: {e}")
        return None

def extract_prescription_with_gemini(image_path):
    """Extract only what is visibly written on a prescription; never infer doses."""
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key or api_key == "your_gemini_api_key_here":
        raise RuntimeError("Prescription scanning is not configured.")
    try:
        genai.configure(api_key=api_key)
        image = Image.open(image_path)
        prompt = '''Read this prescription image. Extract only medicine lines that are visibly legible.
Do not diagnose, recommend, infer missing medicine names, or change a dose. Return STRICT JSON only:
{"medicines":[{"name":"brand or medicine name","strength":"as written or empty","instructions":"as written or empty","duration":"as written or empty"}],"notes":"short note about unreadable content if needed"}
If there are no clearly readable medicine names, return an empty medicines list.'''
        data = _parse_json_response(genai.GenerativeModel("gemini-3.5-flash").generate_content([prompt, image]).text)
        return data if isinstance(data, dict) else {"medicines": [], "notes": "Could not read prescription."}
    except Exception as error:
        print(f"GEMINI_SERVICE ERROR: prescription extraction failed: {error}")
        raise RuntimeError("Could not read the prescription image.") from error

def analyse_report_with_gemini(report_text):
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key: raise RuntimeError("Report analysis is not configured.")
    prompt = f'''You explain a medical report for a patient. Do not diagnose, prescribe, or claim certainty. Use only values present in the report text. Return STRICT JSON:
{{"report_type":"Blood test|Imaging|Other","plain_summary":"short plain summary","highlights":[{{"label":"test name","value":"value","status":"within_range|needs_review|unknown","note":"short explanation"}}],"questions_for_doctor":["question"],"urgent":false,"urgent_reason":""}}
Mark needs_review only if the report itself shows a high/low/abnormal flag or a supplied reference range indicates it. urgent=true only for explicitly critical values/critical flags. Report text:\n{report_text[:24000]}'''
    try:
        genai.configure(api_key=api_key)
        return _parse_json_response(genai.GenerativeModel("gemini-3.5-flash").generate_content(prompt).text)
    except Exception as error:
        raise RuntimeError("Could not analyse the report.") from error

    try:
        print(f"GEMINI_SERVICE: Authenticating and running Gemini Vision on image: {image_path}...")
        genai.configure(api_key=api_key)
        # Using stable gemini-3.5-flash for vision tasks
        model = genai.GenerativeModel("gemini-3.5-flash")
        
        image = Image.open(image_path)
        
        prompt = """
        Analyze this image of a medicine package.
        Identify and extract the following fields. If a field is not found or is unreadable, set its value to null:
        
        1. "brand_name": The corrected brand/product name of the medicine (e.g. "Augmentin 625 Duo Tablet", "Dolo 650", "Metformin 500mg"). Correct any spelling typos.
        2. "expiry_date": The expiry date of the medicine package, normalized into DD/MM/YYYY format if readable.
        3. "batch_number": The manufacturing batch number or batch code.
        4. "mrp": The printed retail price (numerical value only).
        
        Provide your output as a STRICT JSON object only. Do not include markdown code block syntax (like ```json ... ```) or any additional explanation text.
        """
        
        response = model.generate_content([prompt, image])
        response_text = response.text.strip()
        
        # Strip markdown syntax if returned anyway
        if response_text.startswith("```json"):
            response_text = response_text[7:]
        if response_text.endswith("```"):
            response_text = response_text[:-3]
            
        parsed_data = json.loads(response_text.strip())
        print(f"GEMINI_SERVICE: Image analysis complete. Parsed data: {parsed_data}")
        return parsed_data
    except Exception as e:
        print(f"GEMINI_SERVICE ERROR: Failed to call Gemini Vision API: {e}")
        return None

def clean_image_with_gemini(image_path):
    """Extract one medicine package from a photo."""
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key or api_key == "your_gemini_api_key_here": return None
    try:
        genai.configure(api_key=api_key)
        prompt = '''Read this medicine package. Return STRICT JSON only: {"brand_name":"name or null","expiry_date":"DD/MM/YYYY or null","batch_number":"value or null","mrp":"number or null"}.'''
        return _parse_json_response(genai.GenerativeModel("gemini-3.5-flash").generate_content([prompt, Image.open(image_path)]).text)
    except Exception as error:
        print(f"GEMINI_SERVICE ERROR: image scan failed: {error}")
        return None

def chat_with_gemini(system_prompt, message, history, context):
    """
    Query Gemini model for conversational app support with system instruction and context enforcement.
    """
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key or api_key == "your_gemini_api_key_here":
        print("GEMINI_SERVICE: GEMINI_API_KEY is not configured in .env file.")
        return "Sorry, the AI Assistant is currently disabled because the API key is not configured."

    try:
        print("GEMINI_SERVICE: Initializing Gemini API for Chatbot...")
        genai.configure(api_key=api_key)
        model = genai.GenerativeModel("gemini-3.5-flash")
        
        # Build prompt using chat history + context
        prompt_parts = []
        prompt_parts.append(f"SYSTEM INSTRUCTION:\n{system_prompt}\n")
        if context:
            prompt_parts.append(f"CURRENT SCREEN CONTEXT:\n{context}\n")
            
        prompt_parts.append("CONVERSATION HISTORY:")
        for turn in history:
            role = turn.get("role", "user")
            text = turn.get("text", "")
            role_label = "User" if role == "user" else "Assistant"
            prompt_parts.append(f"{role_label}: {text}")
            
        prompt_parts.append(f"User: {message}")
        prompt_parts.append("Assistant:")
        
        full_prompt = "\n".join(prompt_parts)
        
        response = model.generate_content(full_prompt)
        return response.text.strip()
    except Exception as e:
        print(f"GEMINI_SERVICE ERROR: chat_with_gemini failed: {e}")
        # Never expose API keys, quota metadata or raw provider errors in the UI.
        # A short local response keeps the feature useful during free-tier limits.
        return _local_chat_fallback(message)


def _local_chat_fallback(message):
    """Small offline help set used only when the Gemini service is unavailable."""
    text = str(message or "").lower()
    if any(word in text for word in ("schedule", "reminder", "dose", "taken")):
        return "Open a medicine from your Cabinet, set its daily schedule, then use the Home checklist to mark today’s dose as Taken."
    if any(word in text for word in ("scan", "ocr", "prescription")):
        return "Use Add Medication to scan a package or choose Scan Doctor Prescription. Review every detected medicine before adding it to the Cabinet."
    if any(word in text for word in ("allergy", "allergic", "reaction")):
        return "Open Allergy Center to record a trigger and reaction. For breathing difficulty or face, lip, tongue, or throat swelling, seek urgent medical care."
    if any(word in text for word in ("interaction", "drug", "graph")):
        return "Add medicines to the Cabinet, then open Drug Interaction Graph to see documented database matches. A missing match is not a safety guarantee."
    if any(word in text for word in ("report", "pdf", "doctor")):
        return "Use Report Analysis to upload a text-based lab-report PDF, or use Medical Information to export a doctor summary PDF."
    return "The support service is temporarily busy. You can still use Cabinet, Allergy Center, Symptom Checker, Report Analysis, and the doctor PDF export."
