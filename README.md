# BioAttend • Offline-First Facial Recognition Attendance Kiosk

[![Flutter Version](https://img.shields.io/badge/Flutter-3.9.0+-02569B?logo=flutter)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.9.0+-0175C2?logo=dart)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-00E676.svg)](LICENSE)
[![Architecture: Clean](https://img.shields.io/badge/Architecture-Clean%20Architecture-00B0FF.svg)]()
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-orange.svg)]()

**BioAttend** is a production-ready, edge-AI facial recognition attendance terminal application built with Flutter. It operates **100% offline**, performing real-time face detection, temporal stability filtering, 192-dimensional MobileFaceNet feature extraction, and fast 1:N vector similarity matching on-device with zero cloud dependencies or latency.

---

## 🌟 Key Features

- **Real-Time On-Device Face Detection**: Continuous camera stream inference using Google ML Kit Face Detection (`NV21` / `YUV420_888` hardware-accelerated streams).
- **Anti-Flicker Temporal Stability Tracking**: Custom temporal filter (`FaceStabilityTracker`) tracking center drift, bounding box delta, and frame persistence to eliminate false triggers and flickering before inference.
- **192-Dimensional Biometric Embeddings**: MobileFaceNet deep learning model running on TensorFlow Lite (`tflite_flutter`), generating normalized 192-dimensional facial geometry embeddings.
- **High-Precision 1:N Cosine Similarity Matching**: Sub-millisecond vector comparison matching probe faces against cached employee profiles with strict threshold validation (`0.78` cosine similarity).
- **Smart Automatic Punch Toggle (Check-In / Check-Out)**: Automatically determines attendance punch type based on previous daily activity without requiring manual mode selection.
- **Debounce Cooldown Mechanism**: Per-employee time-based cooldown (default 5s) preventing duplicate punches while maintaining immediate responsiveness for subsequent staff.
- **Local ACID Vector Database (Isar)**: Fast, embedded NoSQL database storing employee records and attendance history with binary indexing.
- **Dual-Card Home Portal**: Seamless dual-mode landing hub switching between the Live Kiosk Stream and the Admin Management Hub.
- **Complete Admin Management Dashboard**:
  - **Employee Directory**: Live search, Add Staff (+ Camera Biometric Capture), Edit Name/Code, and Permanent Delete with safety prompts.
  - **Attendance Logs & Reports**: Calendar date-picker filter, daily counters (Total, Check-In, Check-Out), and similarity confidence tracking.
  - **System Diagnostics**: Live health status for AI models, Isar database, and in-memory cache maintenance.

---

## 🛠️ Technology Stack

| Layer / Domain | Technology | Description |
| :--- | :--- | :--- |
| **Framework** | [Flutter](https://flutter.dev) (Dart 3) | Cross-platform UI toolkit with custom painters and dark theme. |
| **State Management** | [Riverpod 2.0](https://riverpod.dev) | Declarative state management, AsyncNotifiers, and reactive providers. |
| **Face Detection** | [Google ML Kit](https://developers.google.com/ml-kit) | High-speed face detection & tracking on live camera frames. |
| **Biometric ML Model** | [TensorFlow Lite](https://www.tensorflow.org/lite) + MobileFaceNet | 192-dimensional normalized face feature vector generation. |
| **Local Persistence** | [Isar Database](https://isar.dev) | Ultra-fast local NoSQL database with native binary vector queries. |
| **Camera & Lifecycle** | `camera` + CameraX | Hardware-accelerated image streaming with clean route handoffs. |
| **Image Processing** | `image` (Dart) | Isolate-backed YUV/NV21 to RGB conversion, bounding box cropping, and normalization. |

---

## 📐 System Architecture & Inference Pipeline

BioAttend follows **Clean Architecture** principles, enforcing strict separation of concerns between presentation, domain contracts, and data sources:

```
                  ┌─────────────────────────────────────┐
                  │          Live Camera Stream         │
                  │        (NV21 / YUV420_888)          │
                  └──────────────────┬──────────────────┘
                                     │
                                     ▼
                  ┌─────────────────────────────────────┐
                  │    Google ML Kit Face Detection     │
                  │      (Dominant Face Filtering)      │
                  └──────────────────┬──────────────────┘
                                     │
                                     ▼
                  ┌─────────────────────────────────────┐
                  │     FaceStabilityTracker (3 Frm)    │
                  │   (Center Drift & BBox Tolerance)   │
                  └──────────────────┬──────────────────┘
                                     │
                                     ▼
                  ┌─────────────────────────────────────┐
                  │    Background Isolate (compute)     │
                  │  • Deep copy raw plane buffers      │
                  │  • Sensor orientation alignment     │
                  │  • 12% padded bounding box crop     │
                  │  • Resize to strictly 112x112       │
                  │  • Normalize pixels to [-1.0, 1.0]  │
                  └──────────────────┬──────────────────┘
                                     │
                                     ▼
                  ┌─────────────────────────────────────┐
                  │   MobileFaceNet TFLite Inference    │
                  │   (192-d L2-Normalized Embedding)   │
                  └──────────────────┬──────────────────┘
                                     │
                                     ▼
                  ┌─────────────────────────────────────┐
                  │   1:N In-Memory Cosine Similarity   │
                  │     (Threshold >= 0.78 Match)       │
                  └──────────┬───────────────────────┬──┘
                             │                       │
                       [Match Found]           [No Match]
                             │                       │
                             ▼                       ▼
                  ┌─────────────────────┐ ┌─────────────────────┐
                  │ • Debounce Check    │ │ • "Unrecognized"    │
                  │ • Smart Punch Type  │ │ • Prompt Retry      │
                  │ • Save to Isar DB   │ └─────────────────────┘
                  │ • Animated Success  │
                  └─────────────────────┘
```

---

## ⚡ Performance Optimizations

1. **Zero-UI-Jank Background Isolates (`compute()`)**:
   - YUV/NV21 raw plane decoding and bitmap matrix calculations run inside background Dart isolates.
   - Deep-copying plane buffers (`Uint8List.fromList`) ensures native camera memory is never recycled before the isolate finishes processing.
2. **Single Main-Thread Interpreter Initialization**:
   - MobileFaceNet TFLite interpreter is initialized once during app startup (`main.dart`), avoiding repeated delegate allocation and garbage collection overhead.
3. **Adaptive Camera Lifecycle Handoff**:
   - Camera controllers are explicitly paused and unmounted before transitioning between the Kiosk and Admin screens, preventing native Android Camera2 hardware session deadlocks.

---

## 📂 Project Structure

```
lib/
├── core/
│   ├── database/                  # Isar database service & initialization
│   ├── ml/                        # ML components
│   │   ├── face_preprocessor.dart # Isolate-backed YUV->RGB, crop & tensor normalization
│   │   ├── face_recognition_service.dart # TFLite MobileFaceNet 192-d inference
│   │   └── face_stability_tracker.dart  # Multi-frame anti-flicker temporal tracker
│   └── utils/
│       ├── camera_image_converter.dart   # CameraImage to ML Kit InputImage bridge
│       └── coordinates_translator.dart  # Canvas coordinate translation & mirroring
├── data/
│   ├── models/                    # Isar Entities (Employee, AttendanceRecord)
│   └── repositories/              # Local attendance repository implementation
├── domain/
│   └── repositories/              # Abstract repository contracts
├── presentation/
│   ├── components/                # Reusable UI components (LiveCameraView, Painter, OverlayCard)
│   ├── controllers/               # LiveMatchingController (1:N search, debounce, punch logic)
│   ├── providers/                 # Riverpod state notifiers & repository providers
│   └── screens/
│       ├── home_screen.dart       # Dual-card portal landing screen
│       ├── attendance_kiosk_screen.dart # Live facial recognition kiosk terminal
│       ├── admin_dashboard_screen.dart  # 3-Tab Admin hub (CRUD, Logs, Settings)
│       └── admin_enrollment_screen.dart # Staff biometric enrollment screen
└── main.dart                      # Application bootstrap & orientation lock
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.9.0 or higher)
- Physical Android or iOS device with camera support (Camera streaming is required for live testing).

### Installation & Run

1. **Clone the repository**:
   ```bash
   git clone https://github.com/BGCODE12/Offline-Facial-Recognition-Attendance.git
   cd Offline-Facial-Recognition-Attendance
   ```

2. **Install Flutter packages**:
   ```bash
   flutter pub get
   ```

3. **Verify Model Asset**:
   Ensure `assets/mobilefacenet.tflite` is present in your `assets/` directory (included with the repository).

4. **Run Code Generation (if modifying models)**:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

5. **Launch the application on your physical device**:
   ```bash
   flutter run --release
   ```

---

## 🧪 Testing Suite

Execute the full suite of unit and integration tests:

```bash
flutter test
```

### Test Coverage includes:
- **`attendance_repository_test.dart`**: Multi-employee Isar persistence, vector integrity, date range filtering, and non-overwriting validation.
- **`face_ml_test.dart`**: L2 normalization verification, synthetic 192-dim vector math, and stability tracking state transitions.
- **`live_matching_test.dart`**: 1:N Cosine similarity accuracy, threshold rejection, 5-second debounce cooldown, and automatic check-in/out toggling.
- **`coordinates_translator_test.dart`**: Camera preview coordinate scaling and front-lens mirroring.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
