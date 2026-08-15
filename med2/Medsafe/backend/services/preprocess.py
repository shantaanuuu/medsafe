import cv2
import os

from config import (
    RESIZE_SCALE,
    DEBUG_FOLDER
)


def preprocess_image(image_path):
    """
    Preprocess image for OCR.
    Returns processed grayscale image.
    """

    image = cv2.imread(image_path)

    if image is None:
        raise Exception("Unable to read image.")

    # --------------------------------
    # Resize
    # --------------------------------

    image = cv2.resize(
        image,
        None,
        fx=RESIZE_SCALE,
        fy=RESIZE_SCALE,
        interpolation=cv2.INTER_CUBIC
    )

    # --------------------------------
    # Convert to grayscale
    # --------------------------------

    gray = cv2.cvtColor(
        image,
        cv2.COLOR_BGR2GRAY
    )

    # --------------------------------
    # Denoise
    # --------------------------------

    gray = cv2.bilateralFilter(
        gray,
        9,
        75,
        75
    )

    # --------------------------------
    # Improve contrast
    # --------------------------------

    clahe = cv2.createCLAHE(
        clipLimit=2.0,
        tileGridSize=(8, 8)
    )

    gray = clahe.apply(gray)

    # --------------------------------
    # Save debug image
    # --------------------------------

    debug_path = os.path.join(
        DEBUG_FOLDER,
        "preprocessed.png"
    )

    cv2.imwrite(debug_path, gray)

    return gray