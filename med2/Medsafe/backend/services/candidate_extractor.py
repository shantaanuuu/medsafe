import re

from stopwords import STOP_WORDS

# --------------------------------------------
# Configuration
# --------------------------------------------

MIN_CONFIDENCE = 60
TOP_CANDIDATES = 10


# --------------------------------------------
# Clean OCR Text
# --------------------------------------------

def clean_word(word):
    """
    Removes punctuation and extra spaces.
    """

    word = re.sub(r"[^A-Za-z0-9]", "", word)

    return word.strip()


# --------------------------------------------
# Validate Candidate
# --------------------------------------------

def is_valid_word(word, confidence):

    if not word:
        return False

    if confidence < MIN_CONFIDENCE:
        return False

    if len(word) < 3:
        return False

    if word.lower() in STOP_WORDS:
        return False

    # Reject numbers like 650, 2024 etc.
    if word.isdigit():
        return False

    return True


# --------------------------------------------
# Candidate Score
# --------------------------------------------

def calculate_score(candidate):
    """
    Score = OCR Confidence + Font Height

    Higher confidence and larger text
    are more likely to be medicine names.
    """

    return (
        candidate["confidence"]
        + candidate["height"]
    )


# --------------------------------------------
# Remove Duplicate Words
# --------------------------------------------

def remove_duplicates(candidates):

    unique = []

    seen = set()

    for candidate in candidates:

        key = candidate["text"].lower()

        if key in seen:
            continue

        seen.add(key)

        unique.append(candidate)

    return unique


# --------------------------------------------
# Sort Candidates
# --------------------------------------------

def sort_candidates(candidates):

    candidates.sort(

        key=lambda x: x["score"],

        reverse=True

    )

    return candidates


# --------------------------------------------
# Main Function
# --------------------------------------------

def extract_candidates(ocr_words):

    candidates = []

    for word in ocr_words:

        text = clean_word(word["text"])

        confidence = word["confidence"]

        if not is_valid_word(text, confidence):
            continue

        candidate = {

            "text": text,

            "confidence": confidence,

            "x": word["x"],

            "y": word["y"],

            "width": word["width"],

            "height": word["height"]

        }

        candidate["score"] = calculate_score(candidate)

        candidates.append(candidate)

    candidates = remove_duplicates(candidates)

    candidates = sort_candidates(candidates)

    return candidates[:TOP_CANDIDATES]