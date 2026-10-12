"""Deterministic medicine-interaction checks backed by medicines.db.

The database provides interaction lists per medicine.  This route only flags a
pair when one cabinet item matches a listed ingredient or brand; an absent
match is deliberately not presented as proof that a pair is safe.
"""
from flask import Blueprint, jsonify, request
import json
import os
import re
import sqlite3

interaction_bp = Blueprint("interactions", __name__)
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.abspath(os.path.join(BASE_DIR, "..", "database", "medicines.db"))


def _normalise(value):
    return re.sub(r"[^a-z0-9]+", " ", str(value or "").lower()).strip()


def _terms(value):
    """Extract useful comparison terms from a generic composition/name."""
    raw = str(value or "")
    raw = re.sub(r"\([^)]*\)", "", raw)
    raw = re.sub(r"\b\d+(?:\.\d+)?\s*(?:mg|mcg|g|ml|%)\b", "", raw, flags=re.I)
    parts = re.split(r"\s*\+\s*|\s*/\s*|\s*,\s*", raw)
    result = {_normalise(raw)}
    result.update(_normalise(part) for part in parts if _normalise(part))
    return {term for term in result if len(term) >= 3}


def _interaction_data(medicine):
    raw = medicine.get("drugInteractions") or medicine.get("drug_interactions")
    if isinstance(raw, dict):
        return raw
    if raw:
        try:
            parsed = json.loads(raw)
            return parsed if isinstance(parsed, dict) else {}
        except (ValueError, TypeError):
            pass

    # Cabinet entries created before interaction support may lack this field.
    med_id = str(medicine.get("id") or "")
    name = str(medicine.get("name") or medicine.get("brandName") or "")
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    try:
        row = conn.execute(
            "SELECT drug_interactions FROM medicines WHERE id = ? OR name = ? LIMIT 1",
            (med_id, name),
        ).fetchone()
        if row and row["drug_interactions"]:
            return json.loads(row["drug_interactions"])
    except (sqlite3.Error, ValueError, TypeError):
        return {}
    finally:
        conn.close()
    return {}


def _matches(target, medicine):
    target_norm = _normalise(target)
    if len(target_norm) < 3:
        return False
    candidates = _terms(medicine.get("genericName") or medicine.get("generic_name"))
    candidates.update(_terms(medicine.get("name") or medicine.get("brandName")))
    return any(target_norm == term or target_norm in term or term in target_norm for term in candidates)


def _severity(effect):
    value = str(effect or "").upper()
    if "LIFE" in value or "SERIOUS" in value or "CONTRA" in value:
        return "major"
    if "MODERATE" in value or "CAUTION" in value:
        return "caution"
    return "monitor"


def _rank(severity):
    return {"major": 3, "caution": 2, "monitor": 1}.get(severity, 0)


@interaction_bp.route("/api/interactions/analyze", methods=["POST"])
def analyze_interactions():
    body = request.get_json(silent=True) or {}
    medicines = body.get("medicines", [])
    if not isinstance(medicines, list):
        return jsonify({"status": "error", "message": "medicines must be a list."}), 400

    medicines = [item for item in medicines if isinstance(item, dict) and item.get("id")]
    links_by_pair = {}
    covered = 0

    for item in medicines:
        item["_rules"] = _interaction_data(item)
        if item["_rules"]:
            covered += 1

    for i, source in enumerate(medicines):
        rules = source.get("_rules", {})
        targets = list(rules.get("drug") or []) + list(rules.get("brand") or [])
        effects = list(rules.get("effect") or [])
        for j, target in enumerate(targets):
            effect = effects[j] if j < len(effects) else "Documented interaction"
            for other in medicines[i + 1:] + medicines[:i]:
                if source["id"] == other["id"] or not _matches(target, other):
                    continue
                key = tuple(sorted((str(source["id"]), str(other["id"]))))
                candidate = {
                    "medicine_a_id": str(source["id"]),
                    "medicine_b_id": str(other["id"]),
                    "severity": _severity(effect),
                    "source_effect": str(effect or "Documented interaction"),
                    "matched_term": str(target),
                    "description": "Database record lists %s with %s as %s." % (
                        target, source.get("genericName") or source.get("name"), effect or "an interaction"
                    ),
                }
                current = links_by_pair.get(key)
                if current is None or _rank(candidate["severity"]) > _rank(current["severity"]):
                    links_by_pair[key] = candidate

    for item in medicines:
        item.pop("_rules", None)
    links = sorted(links_by_pair.values(), key=lambda x: -_rank(x["severity"]))
    return jsonify({"status": "success", "data": {
        "links": links,
        "coverage": {
            "medicines_checked": len(medicines),
            "medicines_with_database_rules": covered,
            "note": "Only documented matches in the available medicine database are flagged. No result is not a safety guarantee.",
        },
    }})
