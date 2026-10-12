"""Privacy-preserving proxy for Google Places healthcare searches."""
import json
import os
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen
from flask import Blueprint, jsonify, request

nearby_healthcare_bp = Blueprint("nearby_healthcare", __name__)
_TYPES = {"hospital": "hospital", "clinic": "doctor", "pharmacy": "pharmacy", "vet": "veterinary_care"}
_FIELDS = "places.id,places.displayName,places.formattedAddress,places.location,places.nationalPhoneNumber,places.businessStatus,places.regularOpeningHours,places.types"

def _post(url, key, payload):
    req = Request(url, data=json.dumps(payload).encode(), method="POST", headers={"Content-Type": "application/json", "X-Goog-Api-Key": key, "X-Goog-FieldMask": _FIELDS})
    with urlopen(req, timeout=12) as response: return json.loads(response.read().decode())

@nearby_healthcare_bp.route("/api/nearby-healthcare", methods=["POST"])
def nearby_healthcare():
    key = os.getenv("GOOGLE_PLACES_API_KEY")
    if not key: return jsonify({"status": "error", "message": "Places search is not configured. Add GOOGLE_PLACES_API_KEY to backend .env."}), 503
    body = request.get_json(silent=True) or {}
    try:
        lat, lng = float(body["latitude"]), float(body["longitude"]); radius = max(500, min(float(body.get("radius", 5000)), 15000))
    except (KeyError, TypeError, ValueError): return jsonify({"status": "error", "message": "Valid latitude and longitude are required."}), 400
    category = str(body.get("category", "hospital")).lower(); circle = {"center": {"latitude": lat, "longitude": lng}, "radius": radius}
    if category == "nursing_home": url, payload = "https://places.googleapis.com/v1/places:searchText", {"textQuery": "nursing home", "locationBias": {"circle": circle}, "maxResultCount": 20}
    else: url, payload = "https://places.googleapis.com/v1/places:searchNearby", {"includedTypes": [_TYPES.get(category, "hospital")], "maxResultCount": 20, "rankPreference": "DISTANCE", "locationRestriction": {"circle": circle}}
    try: data = _post(url, key, payload)
    except HTTPError as exc: return jsonify({"status": "error", "message": "Places search failed: " + exc.read().decode(errors="ignore")[:240]}), 502
    except (URLError, TimeoutError) as exc: return jsonify({"status": "error", "message": "Could not reach Places service: " + str(exc)}), 502
    places = []
    for p in data.get("places", []):
        loc, hours = p.get("location") or {}, p.get("regularOpeningHours") or {}
        if "latitude" not in loc or "longitude" not in loc: continue
        places.append({"id": p.get("id", ""), "name": (p.get("displayName") or {}).get("text", "Healthcare provider"), "address": p.get("formattedAddress", "Address unavailable"), "latitude": loc["latitude"], "longitude": loc["longitude"], "phone": p.get("nationalPhoneNumber"), "open_now": hours.get("openNow"), "types": p.get("types", [])})
    return jsonify({"status": "success", "data": {"places": places, "category": category, "radius": radius}})
