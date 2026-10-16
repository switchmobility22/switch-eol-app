# Switch PowerPedal — End-of-Line (EOL) Assembly & QC Station

Standalone industrial mobile application for factory assembly lines and testing stations provisioning e-bikes powered by the **Switch PowerPedal** powertrain and controller system.

---

## ⚡ Core Architecture

1. **Brand Isolation**: Strict multi-tenant isolation across OEM partner brands (Hero Lectro, Decathlon Rockrider, E-Motorad, eSthira, Daijo, eZPedal, Cypro).
2. **Proximity Discovery Radar**: Automatic BLE discovery filtered to immediate physical contact ($\text{RSSI} \ge -40\text{ dBm}$, $5\text{--}10\text{ cm}$).
3. **1-Tap Provisioning**: Automatic derivation of wheel circumference register from selected production model with 56px gloved button `FLASH & PASS VEHICLE`.
4. **Hardware Quality Gate**: Real-time evaluation of controller error registers (`0xFF`/`0x00`) and Bottom Bracket cadence sensor rotation before passing.
5. **Offline-First Resilience**: Local encrypted SQLite queue commits birth certificates in $<5\text{ms}$; silent background reconciliation engine streams to Firebase Firestore when connectivity resumes.

---

## 🚀 Getting Started

### Prerequisites
* Flutter SDK $\ge 3.0$
* Android Studio / Xcode
* Android device running Android 10+ (API 29+) with Bluetooth Low Energy

### Running the App
```bash
flutter pub get
flutter run
```

### Running Test Suite
```bash
flutter test
flutter analyze
```