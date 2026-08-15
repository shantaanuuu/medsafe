from flask import Flask
from dotenv import load_dotenv
from routes.scan import scan_bp
from routes.user_cabinet import user_cabinet_bp, init_user_tables
from routes.medicine import medicine_bp

load_dotenv()

app = Flask(__name__)

# Initialize user SQLite tables inside medicines.db
init_user_tables()

# =====================================================
# Register Routes
# =====================================================

app.register_blueprint(scan_bp)
app.register_blueprint(user_cabinet_bp)
app.register_blueprint(medicine_bp)

# =====================================================
# Home
# =====================================================

@app.route("/", methods=["GET"])
def home():

    return {
        "status": "success",
        "message": "MedSafe Backend Running",
        "version": "1.0"
    }

# =====================================================
# Run Server
# =====================================================

if __name__ == "__main__":

    app.run(
        host="0.0.0.0",
        port=5000,
        debug=True
    )