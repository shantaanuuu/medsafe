import re


# ==========================================================
# Regex Patterns
# ==========================================================

STRENGTH_PATTERN = r"\b\d+\s?(?:mg|g|ml|mcg)\b"

EXPIRY_PATTERNS = [

    r"EXP(?:IRY)?[:\s\-]*([A-Z]{3}\s?\d{2,4})",

    r"EXP(?:IRY)?[:\s\-]*(\d{2}[/-]\d{2,4})"

]

MFG_PATTERNS = [

    r"MFG[:\s\-]*([A-Z]{3}\s?\d{2,4})",

    r"MFD[:\s\-]*([A-Z]{3}\s?\d{2,4})",

    r"MFG[:\s\-]*(\d{2}[/-]\d{2,4})"

]

BATCH_PATTERNS = [

    r"(?:BATCH|BATCH NO|B\.?NO|LOT)[\s:.-]*([A-Z0-9\-]+)"

]

MRP_PATTERN = r"MRP[\s:₹Rs\.]*([\d]+(?:\.\d+)?)"


# ==========================================================
# Helper
# ==========================================================

def search_patterns(patterns, text):

    for pattern in patterns:

        match = re.search(

            pattern,

            text,

            re.IGNORECASE

        )

        if match:

            return match.group(1).strip()

    return None


# ==========================================================
# Medicine Name
# ==========================================================

def extract_medicine_name(lines):

    candidates = []

    for line in lines:

        line = line.strip()

        if len(line) < 3:
            continue

        upper = line.upper()

        score = 0

        # -----------------------
        # Reject metadata
        # -----------------------

        if upper.startswith(("EXP", "MFG", "MFD", "BATCH", "LOT", "MRP")):
            continue

        # -----------------------
        # Reject pure strength
        # -----------------------

        if re.fullmatch(r"\d+\s?(mg|ml|mcg|g)", line, re.IGNORECASE):
            continue

        # -----------------------
        # Contains letters
        # -----------------------

        if re.search(r"[A-Za-z]", line):
            score += 5

        # -----------------------
        # Brand names often have hyphen
        # Example: PARACIP-500
        # -----------------------

        if "-" in line:
            score += 5

        # -----------------------
        # Mixed letters & digits
        # Example: PARACIP500
        # -----------------------

        if re.search(r"[A-Za-z].*\d|\d.*[A-Za-z]", line):
            score += 4

        # -----------------------
        # Long enough
        # -----------------------

        if len(line) > 5:
            score += 2

        candidates.append((score, line))

    if not candidates:
        return None

    candidates.sort(reverse=True)

    return candidates[0][1]

# ==========================================================
# Main
# ==========================================================
def extract_generic_name(lines):

    for line in lines:

        line = line.strip()

        upper = line.upper()

        if "TABLET" in upper or "CAPSULE" in upper:

            words = line.split()

            generic = []

            for word in words:

                if word.upper() in ["TABLET", "TABLETS", "CAPSULE", "CAPSULES", "IP"]:

                    break

                generic.append(word)

            if generic:

                return " ".join(generic)

    return None


def extract_information(text):

    lines = [

        line.strip()

        for line in text.split("\n")

        if line.strip()

    ]

    medicine = extract_medicine_name(lines)

    strength = None

    strength_match = re.search(

        STRENGTH_PATTERN,

        text,

        re.IGNORECASE

    )

    if strength_match:

        strength = strength_match.group()

    expiry = search_patterns(

        EXPIRY_PATTERNS,

        text

    )

    mfg = search_patterns(

        MFG_PATTERNS,

        text

    )

    batch = search_patterns(

        BATCH_PATTERNS,

        text

    )

    mrp = None

    mrp_match = re.search(

        MRP_PATTERN,

        text,

        re.IGNORECASE

    )

    if mrp_match:

        mrp = mrp_match.group(1)

    generic = extract_generic_name(lines)

    return {

        "brand_name": medicine,

        "generic_name": generic,

        "strength": strength,

        "expiry_date": expiry,

        "manufacturing_date": mfg,

        "batch_number": batch,

        "mrp": mrp

    }