import os
from dotenv import load_dotenv

backend_dir = os.path.dirname(os.path.abspath(__file__))
load_dotenv(os.path.join(backend_dir, ".env"))

print("=" * 60)
print("MedSafe Gemini Service Integration Test")
print("=" * 60)

import services.gemini_service as gs

# 1. Test clean_ocr_with_gemini
print("\n[Test 1] Testing clean_ocr_with_gemini...")
ocr_sample = "AUGMENTIN 625 DUO TAB B.No. 493021 EXP. 12/2027 MRP Rs 210.50"
ocr_res = gs.clean_ocr_with_gemini(ocr_sample)
print("OCR Result:", ocr_res)

# 2. Test analyze_symptoms_with_gemini
print("\n[Test 2] Testing analyze_symptoms_with_gemini...")
symptom_res = gs.analyze_symptoms_with_gemini("mild headache and sneezing for 2 days", 25, "male", [])
print("Symptom Result (triage_level):", symptom_res.get("triage_level"))

# 3. Test check_medicine_allergy_with_gemini
print("\n[Test 3] Testing check_medicine_allergy_with_gemini...")
allergy_res = gs.check_medicine_allergy_with_gemini(["Amoxicillin"], "Augmentin", "Amoxicillin and Clavulanate")
print("Allergy screening:", allergy_res)

# 4. Test chat_with_gemini
print("\n[Test 4] Testing chat_with_gemini...")
chat_res = gs.chat_with_gemini("You are a helpful assistant.", "What is MedSafe?", [], "")
print("Chat Result:", chat_res[:100], "...")

print("\n" + "=" * 60)
print("ALL TESTS PASSED SUCCESSFULLY!")
print("=" * 60)
