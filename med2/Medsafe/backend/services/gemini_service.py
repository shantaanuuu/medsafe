import os
import json
import google.generativeai as genai
from PIL import Image

def clean_ocr_with_gemini(ocr_text):
    """
    Leverages Gemini LLM to extract structured, corrected medicine brand name,
    expiry date, batch number, and price from raw noisy OCR text.
    """
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key or api_key == "your_gemini_api_key_here":
        print("GEMINI_SERVICE: GEMINI_API_KEY is not configured in .env file.")
        return None

    try:
        print("GEMINI_SERVICE: Authenticating and initializing Gemini API for text cleaning...")
        genai.configure(api_key=api_key)
        # Using stable gemini-3.5-flash
        model = genai.GenerativeModel("gemini-3.5-flash")
        
        prompt = f"""
        Analyze the following raw, noisy, and potentially scrambled OCR text captured from a medicine package.
        
        ---
        {ocr_text}
        ---
        
        Your task is to identify and extract the following fields. If a field is not found or is unreadable, set its value to null:
        
        1. "brand_name": The corrected brand/product name of the medicine (e.g. "Augmentin 625 Duo Tablet", "Dolo 650", "Metformin 500mg"). Correct any obvious spelling typos caused by OCR scanning errors.
        2. "expiry_date": The expiry date of the medicine package, normalized into DD/MM/YYYY format if readable.
        3. "batch_number": The manufacturing batch number or batch code.
        4. "mrp": The printed retail price (numerical value only).
        
        Provide your output as a STRICT JSON object only. Do not include markdown code block syntax (like ```json ... ```) or any additional explanation text.
        """
        
        response = model.generate_content(prompt)
        response_text = response.text.strip()
        
        # Strip markdown syntax if returned anyway
        if response_text.startswith("```json"):
            response_text = response_text[7:]
        if response_text.endswith("```"):
            response_text = response_text[:-3]
            
        parsed_data = json.loads(response_text.strip())
        print(f"GEMINI_SERVICE: OCR text analysis complete. Parsed data: {parsed_data}")
        return parsed_data
    except Exception as e:
        print(f"GEMINI_SERVICE ERROR: Failed to call Gemini Text API: {e}")
        return None

def clean_image_with_gemini(image_path):
    """
    Leverages Gemini Multimodal Vision API to extract structured, corrected medicine details
    directly from the captured image package, bypassing device-side OCR limitations and freezing.
    """
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key or api_key == "your_gemini_api_key_here":
        print("GEMINI_SERVICE: GEMINI_API_KEY is not configured in .env file.")
        return None

    try:
        print(f"GEMINI_SERVICE: Authenticating and running Gemini Vision on image: {image_path}...")
        genai.configure(api_key=api_key)
        # Using stable gemini-3.5-flash for vision tasks
        model = genai.GenerativeModel("gemini-3.5-flash")
        
        image = Image.open(image_path)
        
        prompt = """
        Analyze this image of a medicine package.
        Identify and extract the following fields. If a field is not found or is unreadable, set its value to null:
        
        1. "brand_name": The corrected brand/product name of the medicine (e.g. "Augmentin 625 Duo Tablet", "Dolo 650", "Metformin 500mg"). Correct any spelling typos.
        2. "expiry_date": The expiry date of the medicine package, normalized into DD/MM/YYYY format if readable.
        3. "batch_number": The manufacturing batch number or batch code.
        4. "mrp": The printed retail price (numerical value only).
        
        Provide your output as a STRICT JSON object only. Do not include markdown code block syntax (like ```json ... ```) or any additional explanation text.
        """
        
        response = model.generate_content([prompt, image])
        response_text = response.text.strip()
        
        # Strip markdown syntax if returned anyway
        if response_text.startswith("```json"):
            response_text = response_text[7:]
        if response_text.endswith("```"):
            response_text = response_text[:-3]
            
        parsed_data = json.loads(response_text.strip())
        print(f"GEMINI_SERVICE: Image analysis complete. Parsed data: {parsed_data}")
        return parsed_data
    except Exception as e:
        print(f"GEMINI_SERVICE ERROR: Failed to call Gemini Vision API: {e}")
        return None

def chat_with_gemini(system_prompt, message, history, context):
    """
    Query Gemini model for conversational app support with system instruction and context enforcement.
    """
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key or api_key == "your_gemini_api_key_here":
        print("GEMINI_SERVICE: GEMINI_API_KEY is not configured in .env file.")
        return "Sorry, the AI Assistant is currently disabled because the API key is not configured."

    try:
        print("GEMINI_SERVICE: Initializing Gemini API for Chatbot...")
        genai.configure(api_key=api_key)
        model = genai.GenerativeModel("gemini-3.5-flash")
        
        # Build prompt using chat history + context
        prompt_parts = []
        prompt_parts.append(f"SYSTEM INSTRUCTION:\n{system_prompt}\n")
        if context:
            prompt_parts.append(f"CURRENT SCREEN CONTEXT:\n{context}\n")
            
        prompt_parts.append("CONVERSATION HISTORY:")
        for turn in history:
            role = turn.get("role", "user")
            text = turn.get("text", "")
            role_label = "User" if role == "user" else "Assistant"
            prompt_parts.append(f"{role_label}: {text}")
            
        prompt_parts.append(f"User: {message}")
        prompt_parts.append("Assistant:")
        
        full_prompt = "\n".join(prompt_parts)
        
        response = model.generate_content(full_prompt)
        return response.text.strip()
    except Exception as e:
        print(f"GEMINI_SERVICE ERROR: chat_with_gemini failed: {e}")
        return f"Sorry, I encountered an error while processing your request: {str(e)}"
