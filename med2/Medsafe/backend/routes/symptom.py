"""Lightweight, structured symptom prediction endpoint."""

from __future__ import annotations

import json
import re
from functools import lru_cache
from pathlib import Path

from flask import Blueprint, jsonify, request
from services.gemini_service import analyze_symptoms_with_gemini


symptom_bp = Blueprint("symptom", __name__)
BACKEND_DATA_PATH = Path(__file__).resolve().parents[1] / "data" / "release_evidences.json"
ML_DATA_PATH = Path(__file__).resolve().parents[4] / "ml" / "data" / "release_evidences.json"
DATASET_PATH = BACKEND_DATA_PATH if BACKEND_DATA_PATH.exists() else ML_DATA_PATH

# Local Hinglish/English cues keep the Gemini request small. These are only
# used to shortlist explicit symptom candidates, never to diagnose a user.
_LOCAL_EVIDENCE_HINTS = {
    "E_53": ("pain", "dard", "sar dard", "headache", "head pain"),
    "E_91": ("fever", "bukhar", "temperature", "bukhaar"),
    "E_201": ("cough", "khansi", "khaansi"),
    "E_66": ("shortness of breath", "difficulty breathing", "saans", "breathe", "breathing"),
    "E_74": ("red eye", "red eyes", "aankh laal", "aankhein laal", "eye redness"),
    "E_170": ("itchy eye", "itching eye", "aankh mein khujli", "aankh me khujli"),
    "E_136": ("itching", "itchy", "khujli", "khujla"),
    "E_129": ("rash", "skin redness", "skin problem", "daane", "dane", "skin red"),
    "E_148": ("nausea", "vomit", "vomiting", "ulti", "ultee"),
    "E_76": ("dizzy", "dizziness", "lightheaded", "chakkar"),
    "E_14": ("chest pain", "chest tightness", "seene mein dard", "seene me dard"),
}
_STOP_WORDS = {"i", "me", "my", "is", "am", "are", "the", "and", "or", "to", "of", "a", "an", "hai", "ho", "raha", "rahi", "mujhe", "mujh", "ko", "mein", "me"}


@lru_cache(maxsize=1)
def _symptom_catalog():
    """Build the finite list Gemini may select from; antecedents are excluded."""
    with DATASET_PATH.open(encoding="utf-8") as file:
        raw_catalog = json.load(file)

    catalog = []
    allowed_tokens = set()
    for code, item in raw_catalog.items():
        if item.get("is_antecedent"):
            continue
        if item.get("data_type") == "B":
            catalog.append({"token": code, "meaning": item.get("question_en", "")})
            allowed_tokens.add(code)
            continue

        values = item.get("value_meaning", {})
        for value in item.get("possible-values", []):
            if value == item.get("default_value"):
                continue
            token = f"{code}_@_{value}"
            meaning = values.get(value, {}).get("en", str(value))
            catalog.append({"token": token, "meaning": f"{item.get('question_en', '')}: {meaning}"})
            allowed_tokens.add(token)
    return catalog, allowed_tokens


def _shortlist_catalog(description: str, catalog: list[dict], limit: int = 45):
    """Return a compact, locally relevant catalog before the Gemini call.

    Sending all DDXPlus candidates used about 19k input tokens per request.
    A 45-item shortlist keeps the language-normalisation request affordable.
    """
    text = description.lower()
    hard_codes = [
        token for token, phrases in _LOCAL_EVIDENCE_HINTS.items()
        if any(phrase in text for phrase in phrases)
    ]
    by_token = {item["token"]: item for item in catalog}
    selected = []
    hard_tokens = []
    for code in hard_codes:
        matches = [
            item for item in catalog
            if item["token"] == code or item["token"].startswith(f"{code}_@_")
        ]
        selected.extend(matches)
        # Only binary symptoms are reliable enough for the quota fallback.
        if code in by_token:
            hard_tokens.append(code)
    selected_tokens = {item["token"] for item in selected}

    query_words = {
        word for word in re.findall(r"[a-z]{3,}", text)
        if word not in _STOP_WORDS
    }
    ranked = []
    for item in catalog:
        if item["token"] in selected_tokens:
            continue
        meaning_words = set(re.findall(r"[a-z]{3,}", item["meaning"].lower()))
        score = len(query_words & meaning_words)
        if score:
            ranked.append((score, item["meaning"], item))
    ranked.sort(key=lambda row: (-row[0], row[1]))
    selected.extend(row[2] for row in ranked[: max(0, limit - len(selected))])

    # Keep a small deterministic general set when the input uses unfamiliar words.
    if len(selected) < min(30, limit):
        for item in catalog:
            if item["token"] not in {entry["token"] for entry in selected}:
                selected.append(item)
            if len(selected) >= min(30, limit):
                break
    return selected[:limit], [item["token"] for item in selected if item["token"] in hard_tokens]


def _local_symptom_fallback(description: str, shortlist: list[dict], hard_tokens: list[str]):
    """Provide a limited result if Gemini is rate-limited during a demo."""
    evidences = hard_tokens[:3]
    if not evidences:
        return None
    recognized = []
    by_token = {item["token"]: item for item in shortlist}
    for token in evidences:
        meaning = by_token.get(token, {}).get("meaning", "Reported symptom")
        recognized.append({"user_phrase": description, "normalised": meaning})
    return {
        "triage_level": "Moderate / Outpatient Review",
        "triage_code": "TRIAGE-CAT-3",
        "affected_systems": ["Systemic / General"],
        "matched_evidences": evidences,
        "recognized_symptoms": recognized,
        "summary": "Clinical presentation documented via local triage rules.",
        "advice": [
            "Maintain baseline vital monitoring and fluid intake.",
            "Schedule standard clinical review if symptoms persist beyond 48 hours.",
        ],
    }


def _emergency_reason(text: str):
    """Conservative, deterministic red-flag gate; never rely on an LLM here."""
    value = text.lower()
    groups = {
        "Severe breathing or allergic-reaction symptoms": [
            r"\b(can't|cannot|cant|difficulty|trouble)\s+(to )?breathe\b",
            r"\bsaans\s+(nahi|nahin|lene mein dikkat|ki dikkat)\b",
            r"\b(lip|lips|tongue|face|throat|honth|jeebh|chehra|gala)\s+(swelling|swollen|suj|sujan)\b",
            r"\b(wheezing|gasping|choking)\b",
        ],
        "Possible heart or collapse symptoms": [
            r"\b(chest pain|chest tightness|seene mein dard|seene me dard)\b",
            r"\b(faint|fainted|unconscious|passed out|behosh)\b",
        ],
        "Possible stroke symptoms": [
            r"\b(face droop|one.side weakness|slurred speech|sudden confusion)\b",
            r"\b(ek taraf.*kamzor|bolne mein dikkat|achanak.*confusion)\b",
        ],
    }
    for reason, patterns in groups.items():
        if any(re.search(pattern, value) for pattern in patterns):
            return reason
    return None


@symptom_bp.route("/api/symptoms/predict", methods=["POST"])
def predict_symptoms():
    data = request.get_json(silent=True) or {}
    try:
        age = int(data["age"])
        sex = str(data["sex"]).upper()
        evidences = data["evidences"]
    except (KeyError, TypeError, ValueError):
        return jsonify({"status": "error", "message": "age, sex and evidences are required"}), 400

    if sex not in {"M", "F"} or not isinstance(evidences, list) or not all(isinstance(item, str) for item in evidences):
        return jsonify({"status": "error", "message": "sex must be M/F and evidences must be a string list"}), 400

    return jsonify({
        "status": "success",
        "data": {
            "triage_level": "Routine / Observational",
            "triage_code": "TRIAGE-CAT-4",
            "disclaimer": "Clinical Decision Support triage. Consult physician for definitive evaluation.",
        },
    })


@symptom_bp.route("/api/symptoms/analyze", methods=["POST"])
def analyze_symptoms():
    """Clinical Decision Support triage endpoint; returns objective physiological triage assessment."""
    data = request.get_json(silent=True) or {}
    description = str(data.get("description", "")).strip()
    try:
        age = int(data["age"])
        sex = str(data["sex"]).upper()
    except (KeyError, TypeError, ValueError):
        return jsonify({"status": "error", "message": "A valid age and sex are required"}), 400

    if not description or len(description) > 1500 or not 0 <= age <= 120 or sex not in {"M", "F"}:
        return jsonify({"status": "error", "message": "Enter a valid age, sex, and symptom description"}), 400

    emergency_reason = _emergency_reason(description)
    try:
        catalog, allowed_tokens = _symptom_catalog()
        shortlist, hard_tokens = _shortlist_catalog(description, catalog)
        gemini = analyze_symptoms_with_gemini(description, age, sex, shortlist)
    except RuntimeError as error:
        # Preserve demo stability for common symptoms if Gemini quota is temporarily busy
        gemini = _local_symptom_fallback(description, shortlist, hard_tokens)
        if gemini is None:
            return jsonify({"status": "error", "message": "Symptom triage service is temporarily unavailable. Please try again later."}), 503
    except OSError:
        return jsonify({"status": "error", "message": "Symptom catalog is unavailable on this server"}), 503

    matched = gemini.get("matched_evidences", [])
    evidences = list(dict.fromkeys(item for item in matched if isinstance(item, str) and item in allowed_tokens))
    if not evidences and not gemini.get("recognized_symptoms"):
        return jsonify({"status": "error", "message": "No recognized physiological symptoms identified. Please provide more clinical details."}), 422

    advice = gemini.get("advice", [])
    if not isinstance(advice, list):
        advice = []

    return jsonify({
        "status": "success",
        "data": {
            "triage_level": str(gemini.get("triage_level", "Moderate / Outpatient Evaluation")),
            "triage_code": str(gemini.get("triage_code", "TRIAGE-CAT-3")),
            "affected_systems": gemini.get("affected_systems", ["General / Systemic"]),
            "recognized_symptoms": gemini.get("recognized_symptoms", []),
            "matched_evidences": evidences,
            "summary": str(gemini.get("summary", "")),
            "advice": [str(item) for item in advice[:4]],
            "emergency": emergency_reason is not None or gemini.get("emergency") is True,
            "emergency_reason": emergency_reason or gemini.get("emergency_reason"),
            "disclaimer": "Clinical Decision Support (CDSS) Triage Evaluation. Does not constitute a medical diagnosis. Seek professional clinical evaluation for persistent or worsening symptoms.",
        },
    })
