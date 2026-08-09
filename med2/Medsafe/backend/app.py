from flask import Flask
from dotenv import load_dotenv
from routes.scan import scan_bp
from routes.user_cabinet import user_cabinet_bp

load_dotenv()

app = Flask(__name__)

# =====================================================
# Register Routes
# =====================================================

app.register_blueprint(scan_bp)
app.register_blueprint(user_cabinet_bp)

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