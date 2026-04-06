# Boi Delivery Robot System - Project Context

## Project Overview

**Boi** is an autonomous delivery robot system consisting of three main components:

1. **Flutter Mobile App** (`lib/`) - Customer-facing application for placing orders and controlling the robot
2. **ESP32 Robot Firmware** (`robots/`) - Embedded firmware for motor control, sensors, and WiFi communication
3. **UDP Network Communication** - Real-time command transmission over phone WiFi hotspot

The app enables users to browse products, manage shopping carts, place orders with payment processing, collect coupons, and trigger physical robot delivery via UDP commands. The robot responds to movement commands (forward, backward, left, right, stop, line-follow) sent over UDP.

## Tech Stack

### Flutter App
- **Framework**: Flutter SDK ^3.11.1, Dart ^3.11.1
- **State Management**: Provider (`CartProvider`, `SettingsProvider`, `RobotApi`)
- **Key Dependencies**:
  - `provider` - State management
  - `device_preview` - Multi-device preview during development
  - `audioplayers` - Sound playback
  - `shared_preferences` - Local persistence
- **Linting**: `flutter_lints` with `flutter analyze`

### ESP32 Firmware
- **Platform**: Arduino/ESP32
- **Key Components**: WiFi UDP, Motor PWM (L298N driver), PID line following, Ultrasonic sensor

## Project Structure

```
boi/
├── lib/                        # Flutter application source
│   ├── main.dart               # App entry point with DevicePreview and Providers
│   ├── pages/                  # UI screens
│   │   ├── splash_screen.dart
│   │   ├── home_page.dart
│   │   ├── cart_page.dart
│   │   ├── product_detail_page.dart
│   │   ├── category_products_page.dart
│   │   ├── payment_page.dart
│   │   ├── order_history_page.dart
│   │   ├── order_detail_page.dart
│   │   ├── coupon_page.dart
│   │   └── robot_control_page.dart
│   ├── providers/              # State management (ChangeNotifier)
│   │   ├── cart_provider.dart
│   │   └── settings_provider.dart
│   ├── services/               # Business logic
│   │   └── robot_api.dart      # ⭐ UDP communication with ESP32 robot
│   ├── widgets/                # Reusable UI components
│   ├── theme/                  # App theming (AppTheme)
│   └── utils/                  # Utility functions
├── robots/                     # ESP32 firmware
│   ├── robots.ino              # Main Arduino program
│   ├── config.h                # WiFi & pin configuration
│   ├── motor_control.h         # Motor PWM control
│   ├── pid_control.h           # PID line-follow algorithm
│   └── wifi_manager_example.ino # WiFiManager reference
├── docs/                       # Documentation
│   ├── README.md               # Documentation index
│   ├── QUICK_START.md          # 5-minute setup guide
│   ├── SYSTEM_OVERVIEW.md      # Architecture overview
│   ├── NETWORK_SETUP.md        # WiFi configuration
│   ├── DEBUG_GUIDE.md          # Troubleshooting
│   ├── API_REFERENCE.md        # Robot API docs
│   └── CODE_STRUCTURE.md       # Project organization
├── assets/                     # Static resources
│   ├── images/                 # Images (Logo.JPG, etc.)
│   └── sounds/                 # Sound files
├── test/                       # Unit/widget tests
│   └── widget_test.dart
├── android/                    # Android platform code
├── ios/                        # iOS platform code
├── web/                        # Web platform code
├── linux/                      # Linux desktop platform code
├── macos/                      # macOS desktop platform code
└── windows/                    # Windows desktop platform code
```

## Building and Running

### Prerequisites
- Flutter SDK 3.11.1+
- Android device/emulator or iOS simulator
- Arduino IDE with ESP32 support (for robot firmware)
- Phone with WiFi hotspot capability

### Flutter App

```bash
# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Run with device preview enabled (development mode)
flutter run

# Build release APK
flutter build apk --release

# Build release iOS
flutter build ios --release

# Code analysis
flutter analyze

# Run tests
flutter test
```

### ESP32 Firmware
1. Open `robots/robots.ino` in Arduino IDE
2. Configure WiFi credentials in `config.h`
3. Upload to ESP32 board

### Network Setup
- Phone creates WiFi hotspot: SSID `Boi`, Password `12345678`, Band `2.4GHz`
- ESP32 connects as station to this hotspot
- Communication via UDP on port `2001`
- Commands: `F` (forward), `B` (backward), `L` (left), `R` (right), `S` (stop), `LF` (line follow)

## Architecture

### Communication Flow
```
Phone (Flutter App)
  Creates Hotspot: "Boi"
  IP: 192.168.43.1
        │
        │ WiFi (UDP Port 2001)
        │
        ▼
  ESP32 Robot
  IP: 192.168.43.XXX
  Commands: F, B, L, R, S, LF
```

### Key Design Patterns
- **Provider Pattern**: State management via `ChangeNotifierProvider`
- **Service Layer**: `RobotApi` handles all UDP communication with retry mechanism (3x redundancy)
- **Auto-Discovery**: Robot automatically discovers ESP32 on network via UDP broadcast
- **Dead-man's Switch**: 1.5s safety timeout on ESP32 stops robot if no commands received

### RobotApi Service (`lib/services/robot_api.dart`)
- Type-safe commands via `RobotCommand` enum
- Connection status tracking (`RobotConnectionStatus`)
- UDP socket communication with `RawDatagramSocket`
- Multiple robot support with discovery and selection
- Retry mechanism (sends commands 3x with 50ms delay)
- Auto-discovery on app initialization

## Development Conventions

- **Code Style**: Follows Flutter/Dart conventions with `flutter_lints`
- **Analysis**: Run `flutter analyze` before committing
- **Testing**: Tests located in `test/` directory; run with `flutter test`
- **Debug Mode**: `DevicePreview` enabled in non-release builds for multi-device testing
- **Error Handling**: `RobotApi` uses try-catch with `RobotResponse` objects containing success/failure status

## Current Status

| Component         | Status         | Notes                                     |
| ----------------- | -------------- | ----------------------------------------- |
| Flutter UI        | ✅ Production  | Full ordering system                      |
| Robot API         | ✅ Production  | Service layer with error handling         |
| ESP32 Firmware    | ✅ Production  | Motor control + PID                       |
| UDP Communication | ✅ Tested      | 3x redundancy implemented                 |
| WiFi Config       | ⚠️ In Progress | Hardcoded credentials (needs WiFiManager) |

## Roadmap

### Short Term
- WiFiManager integration for ESP32
- Command acknowledgment (ESP32 → App)

### Medium Term
- Battery monitoring
- Delivery route planning
- Push notifications

## Useful Commands

```bash
# Development
flutter pub get          # Install dependencies
flutter run              # Run on device
flutter analyze          # Code analysis
flutter test             # Run tests

# Building
flutter build apk --release    # Build Android APK
flutter build ios --release    # Build iOS app

# ESP32
# Open robots/robots.ino in Arduino IDE and upload
```

## Key Files

| File | Description |
|------|-------------|
| `lib/main.dart` | App entry point with Providers and DevicePreview |
| `lib/services/robot_api.dart` | UDP communication service with robot |
| `lib/providers/cart_provider.dart` | Shopping cart and order state management |
| `lib/providers/settings_provider.dart` | App settings (theme, etc.) |
| `robots/robots.ino` | Main ESP32 firmware |
| `robots/config.h` | ESP32 configuration (WiFi, pins) |
| `pubspec.yaml` | Flutter dependencies and assets configuration |
