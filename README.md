# Boi Delivery Robot System

A complete autonomous delivery robot system with Flutter mobile app, ESP32 robot firmware, and UDP network communication.

---

## Quick Start

**Get up and running in 5 minutes**: [Quick Start Guide](./docs/QUICK_START.md)

---

## Documentation

Comprehensive documentation is available in the [`docs/`](./docs/) directory:

| Document                                        | Description                      |
| ----------------------------------------------- | -------------------------------- |
| [📖 Docs Home](./docs/README.md)                | Documentation index and overview |
| [⚡ Quick Start](./docs/QUICK_START.md)         | 5-minute setup guide             |
| [🏗️ System Overview](./docs/SYSTEM_OVERVIEW.md) | Architecture and features        |
| [📡 Network Setup](./docs/NETWORK_SETUP.md)     | WiFi configuration               |
| [🐛 Debug Guide](./docs/DEBUG_GUIDE.md)         | Troubleshooting & testing        |
| [🔌 API Reference](./docs/API_REFERENCE.md)     | Robot API documentation          |
| [📁 Code Structure](./docs/CODE_STRUCTURE.md)   | Project organization             |

---

## What is Boi?

Boi is an autonomous delivery robot system that allows users to:

- 🛒 Browse products and place orders via mobile app
- 🤖 Trigger physical robot delivery via UDP commands
- 📦 Track orders and delivery status in real-time
- 🎟️ Collect and apply discount coupons

The system consists of:

1. **Flutter Mobile App** - User interface for ordering
2. **ESP32 Robot Firmware** - Motor control and sensors
3. **UDP Network Communication** - Real-time command transmission over phone WiFi hotspot

---

## Project Structure

```
boi/
├── lib/                    # Flutter application
│   ├── main.dart           # Entry point
│   ├── pages/              # UI screens
│   ├── widgets/            # Reusable components
│   ├── providers/          # State management
│   ├── services/           # Business logic (Robot API ⭐)
│   └── theme/              # Styling
├── robots/                 # ESP32 firmware
│   ├── robots.ino          # Main program
│   ├── config.h            # Configuration
│   └── *.h                 # Motor & PID control
├── docs/                   # Documentation ⭐
├── assets/                 # Images & sounds
└── test/                   # Unit tests
```

**Learn more**: [Code Structure Guide](./docs/CODE_STRUCTURE.md)

---

## Features

### Flutter App

- Product browsing with categories
- Shopping cart with quantity control
- Coupon collection system
- Payment processing with address selection
- Robot control via UDP
- Order history and tracking
- Incoming call notification (robot arrival)
- Rating system after delivery

### ESP32 Robot

- WiFi connectivity (station mode)
- UDP command processing
- Motor PWM control (L298N driver)
- PID line following
- Safety timeout (1.5s dead-man's switch)
- Auto WiFi reconnect

### Network

- Phone WiFi hotspot communication
- UDP broadcast with 3x redundancy
- Automatic IP discovery
- Connection status tracking

---

## Getting Started

### Prerequisites

**Flutter App**:

- Flutter SDK 3.11.1+
- Android device or emulator
- Phone with WiFi hotspot capability

**ESP32 Robot**:

- ESP32 Development Board
- L298N Motor Driver + 2x DC Motors
- Arduino IDE with ESP32 support

### Installation

1. **Clone repository**

   ```bash
   git clone <repository-url>
   cd boi
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Flash ESP32 firmware**
   - Open `robots/robots.ino` in Arduino IDE
   - Upload to ESP32 board

4. **Set up WiFi hotspot**
   - SSID: `Boi`
   - Password: `12345678`
   - Band: 2.4GHz

5. **Run Flutter app**
   ```bash
   flutter run
   ```

**Detailed instructions**: [Quick Start Guide](./docs/QUICK_START.md)

---

## Network Architecture

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

**Learn more**: [Network Setup Guide](./docs/NETWORK_SETUP.md)

---

## Testing

Run tests:

```bash
flutter test
```

Test robot communication:

- See [Debug Guide](./docs/DEBUG_GUIDE.md) for UDP testing methods
- Use Python mock server or netcat to verify communication

---

## Development

### Build APK

```bash
flutter build apk --release
```

### Build iOS

```bash
flutter build ios --release
```

### Code Analysis

```bash
flutter analyze
```

---

## Current Status

| Component         | Status         | Notes                                     |
| ----------------- | -------------- | ----------------------------------------- |
| Flutter UI        | ✅ Production  | Full ordering system                      |
| Robot API         | ✅ Production  | Service layer with error handling         |
| ESP32 Firmware    | ✅ Production  | Motor control + PID                       |
| UDP Communication | ✅ Tested      | 3x redundancy implemented                 |
| WiFi Config       | ⚠️ In Progress | Hardcoded credentials (needs WiFiManager) |

---

## Roadmap

### Short Term

- [ ] WiFiManager integration for ESP32
- [ ] Manual robot control page
- [ ] Robot connection status indicator
- [ ] Command acknowledgment (ESP32 → App)

### Medium Term

- [ ] Battery monitoring
- [ ] Multiple robot support
- [ ] Delivery route planning
- [ ] Push notifications

---

_Last Updated: 2026-04-06_
