# MedSafe 💊

An intelligent medication management and safety assistant built with Flutter, Firebase, and Flask. MedSafe helps individuals and caregivers manage prescriptions, track drug recalls, schedule dose reminders, and receive proactive warnings before medicines expire.

---

## 🌟 Key Features

- **Blister & Box OCR Scanning**: Quick medicine package scanning to extract medicine names, expiry dates, and dosage details.
- **Dose Reminder Alarms**: Exact daily medication reminders powered by `flutter_local_notifications` with high-priority audio alerts.
- **Safety Expiry Alerts**: Proactive warnings before medications expire (at 7 days, 1 day, and on expiry day).
- **Drug Recall & Batch Verification**: Safety checks against active drug recall advisories.
- **Caregiver & Dependent Profiles**: Multi-profile management allowing caregivers to oversee and track schedules for family members.
- **AI Health Assistant**: Integrated healthcare conversational assistant powered by Gemini.

---

## 🚀 Getting Started

### 1. Prerequisites
- **Flutter SDK**: `>=3.3.0`
- **Python**: `>=3.10` (for the Flask backend)
- **Android / iOS Device or Emulator**

### 2. Backend Setup
Navigate to the backend directory and start the Flask server:
```bash
cd med2/Medsafe/backend
pip install -r requirements.txt
python app.py
```
*The server starts on `http://0.0.0.0:5000`.*

### 3. Running the App
Run the Flutter app with your backend server URL:
```bash
flutter run --dart-define=BACKEND_BASE_URL=http://<YOUR_LOCAL_IP>:5000
```
*(You can also configure or change the backend IP at any time directly inside the app).*

---

## 🛡️ Contributors
- Developed by the MedSafe Team.
