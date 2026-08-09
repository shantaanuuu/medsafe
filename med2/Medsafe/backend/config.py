"""
MedSafe Backend Configuration
"""

import os

# ==========================================================
# Project Directories
# ==========================================================

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

UPLOAD_FOLDER = os.path.join(BASE_DIR, "uploads")
DEBUG_FOLDER = os.path.join(BASE_DIR, "debug")
TEST_IMAGES_FOLDER = os.path.join(BASE_DIR, "test_images")

os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(DEBUG_FOLDER, exist_ok=True)
os.makedirs(TEST_IMAGES_FOLDER, exist_ok=True)

# ==========================================================
# Flask
# ==========================================================

MAX_CONTENT_LENGTH = 10 * 1024 * 1024

ALLOWED_EXTENSIONS = {
    "png",
    "jpg",
    "jpeg"
}

# ==========================================================
# Tesseract OCR
# ==========================================================

# Change only if Tesseract is installed elsewhere
TESSERACT_PATH = r"C:\Program Files\Tesseract-OCR\tesseract.exe"

# OCR Engine
OCR_ENGINE_MODE = 3

# Page Segmentation Mode
# 6 = Uniform Block of Text
OCR_PAGE_SEGMENTATION = 6

TESSERACT_CONFIG = (
    f"--oem {OCR_ENGINE_MODE} "
    f"--psm {OCR_PAGE_SEGMENTATION}"
)

OCR_CONFIDENCE_THRESHOLD = 45

# ==========================================================
# Image Processing
# ==========================================================

RESIZE_SCALE = 2.0

GAUSSIAN_BLUR_KERNEL = (3, 3)

CLAHE_CLIP_LIMIT = 2.0

CLAHE_TILE_GRID_SIZE = (8, 8)

# ==========================================================
# Medicine Extraction
# ==========================================================

MIN_WORD_LENGTH = 3

MAX_CANDIDATES = 15

STOP_WORDS = {
    "tablet",
    "tablets",
    "capsule",
    "capsules",
    "strip",
    "medicine",
    "dosage",
    "manufactured",
    "marketed",
    "batch",
    "warning",
    "contains",
    "store",
    "doctor",
    "composition",
    "keep",
    "children",
    "prescription",
    "only",
    "schedule",
    "colour",
    "colours",
    "ip",
    "usp"
}

# ==========================================================
# Regex Patterns
# ==========================================================

EXPIRY_REGEX = [
    r"EXP[:\s]*([A-Z]{3}\s?\d{2,4})",
    r"EXPIRY[:\s]*([A-Z]{3}\s?\d{2,4})",
    r"EXP[:\s]*(\d{2}/\d{2,4})",
    r"EXP[:\s]*(\d{2}-\d{2,4})"
]

MFG_REGEX = [
    r"MFG[:\s]*([A-Z]{3}\s?\d{2,4})",
    r"MFD[:\s]*([A-Z]{3}\s?\d{2,4})",
    r"MFG[:\s]*(\d{2}/\d{2,4})",
    r"MFG[:\s]*(\d{2}-\d{2,4})"
]

BATCH_REGEX = [
    r"(?:BATCH|B\.?NO|LOT)[\s:]*([A-Z0-9\-]+)"
]

MRP_REGEX = [
    r"MRP[\s:₹Rs\.]*([\d\.]+)"
]

STRENGTH_REGEX = [
    r"\b\d+\s?(?:mg|g|ml|mcg)\b"
]

# ==========================================================
# MySQL
# ==========================================================

DB_HOST = "localhost"

DB_PORT = 3306

DB_USER = "root"

DB_PASSWORD = ""

DB_NAME = "medsafe"