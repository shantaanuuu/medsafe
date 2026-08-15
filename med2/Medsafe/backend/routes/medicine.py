from flask import Blueprint, request, jsonify
import sqlite3
import os

medicine_bp = Blueprint("medicine", __name__)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.abspath(os.path.join(BASE_DIR, "..", "database", "medicines.db"))

@medicine_bp.route("/api/medicines/search", methods=["GET"])
def search_medicines():
    query = request.args.get("q", "").strip()
    if not query or len(query) < 2:
        return jsonify({"status": "success", "data": []})

    try:
        conn = sqlite3.connect(DB_PATH)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()

        # Query database for brand names or generic composition matching query string
        cursor.execute(
            "SELECT id, name, generic_name, price, manufacturer_name, substitutes, side_effects FROM medicines WHERE name LIKE ? OR generic_name LIKE ? LIMIT 30",
            (f"%{query}%", f"%{query}%")
        )
        rows = cursor.fetchall()
        conn.close()

        results = []
        for r in rows:
            results.append({
                "id": str(r["id"]),
                "brand_name": r["name"],
                "generic_name": r["generic_name"],
                "price": str(r["price"]) if r["price"] else None,
                "manufacturer": r["manufacturer_name"],
                "substitutes": r["substitutes"],
                "side_effects": r["side_effects"]
            })

        return jsonify({"status": "success", "data": results})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500
