# Boi Robot Delivery System - Documentation

## Documentation Index

### Getting Started

- **[System Overview](./SYSTEM_OVERVIEW.md)** - Architecture, features, and how it works
- **[Quick Start Guide](./QUICK_START.md)** - Get up and running in 5 minutes
- **[Network Setup](./NETWORK_SETUP.md)** - WiFi hotspot configuration and troubleshooting

### Development

- **[Debug Guide](./DEBUG_GUIDE.md)** - Test and troubleshoot UDP communication
- **[API Reference](./API_REFERENCE.md)** - Robot API service documentation
- **[Code Structure](./CODE_STRUCTURE.md)** - Project organization and architecture

### Hardware

- **[ESP32 Setup](./ESP32_SETUP.md)** - Firmware installation and configuration
- **[Robot Assembly](./ROBOT_ASSEMBLY.md)** - Hardware components and wiring

### Advanced

- [`robots/`](../robots/) - ESP32 firmware source code
- [`lib/services/`](../lib/services/) - API service layer
- [`lib/providers/`](../lib/providers/) - State management

---

## Quick Links

| I Want To...             | Go To                                   |
| ------------------------ | --------------------------------------- |
| Set up WiFi connection   | [Network Setup](./NETWORK_SETUP.md)     |
| Test robot communication | [Debug Guide](./DEBUG_GUIDE.md)         |
| Understand the API       | [API Reference](./API_REFERENCE.md)     |
| Install ESP32 firmware   | [ESP32 Setup](./ESP32_SETUP.md)         |
| See system architecture  | [System Overview](./SYSTEM_OVERVIEW.md) |

---

## System Components

### Flutter Application

- **Location**: `lib/`
- **Purpose**: User interface for ordering and robot control
- **Key Features**:
  - Product browsing and cart management
  - Payment processing
  - Robot communication via UDP
  - Order tracking and history

### ESP32 Robot Firmware

- **Location**: `robots/`
- **Purpose**: Motor control, sensors, and command processing
- **Key Features**:
  - UDP command reception
  - Motor PWM control
  - PID line following
  - Safety timeout (1.5s dead-man's switch)

### Network Communication

- **Protocol**: UDP (User Datagram Protocol)
- **Port**: 2001
- **Network Type**: Phone WiFi Hotspot (Local Ad-Hoc Network)
- **Commands**: F (Forward), B (Backward), L (Left), R (Right), S (Stop), LF (Line Follow)

---

## Current Status

| Component         | Status              | Notes                                     |
| ----------------- | ------------------- | ----------------------------------------- |
| Flutter UI        | ✅ Production Ready | Full ordering system                      |
| Robot API         | ✅ Production Ready | Service layer with error handling         |
| ESP32 Firmware    | ✅ Production Ready | Motor control + PID                       |
| UDP Communication | ✅ Tested           | 3x redundancy implemented                 |
| Network Config    | ⚠️ In Progress      | Hardcoded credentials (needs WiFiManager) |

---

_Last Updated: 2026-04-06_
