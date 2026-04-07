# System Overview

## What Is Boi?

Boi is an autonomous delivery robot system consisting of:

1. **Flutter Mobile App** - User interface for ordering and tracking
2. **ESP32 Robot Firmware** - Motor control and sensor management
3. **UDP Network Communication** - Real-time command transmission

The system allows users to place orders via a mobile app, which then triggers a physical robot to deliver the items.

---

## System Architecture

```text
┌─────────────────────────────────────────────────────────────┐
│                     USER (Customer)                                                                                                      │
│                          │                                                                                                                               │
│                          ▼                                                                                                                               │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │           Flutter Mobile Application                                                                                       │  │
│  │  ┌────────────┐  ┌──────────┐  ┌───────────────────────────┐ │  │
│  │  │ Home Page        │  │ Cart                 │  │ Payment Page                                        │ │  │
│  │  │ - Products          │  │ - Items           │  │ - Address                                                 │ │  │
│  │  │ - Search              │  │ - Coupons     │  │ - Payment Method                                 │ │  │
│  │  │ - Categories       │ │ - Total             │  │ - Confirm                                                  │ │  │
│  │  └────────────┘  └──────────┘  └────────┬──────────────────┘ │  │
│  │  ┌────────────┐  ┌──────────┐                         │                                                 │  │
│  │  │ Orders                │  │ Coupons        │                         ▼                                                 │  │
│  │  │ - History             │  │ - Collect        │  ┌─────────────────┐                           │  │
│  │  │ - Track                │  │ - Apply           │  │  RobotApi                       │                            │  │
│  │  └────────────┘  └──────────┘ │  Service                           │                            │  │
│  │                                 └────────┬────────┘                                                                  │  │
│  └──────────────────────────────────────────────┼──────────┘   │
└────────────────────────────────────────────────┼────────────┘
                                              │
                                    UDP (Port 2001)
                                    Command: "F"
                                              │
                                              ▼
                    ┌─────────────────────────────────────┐
                    │         Phone WiFi Hotspot                                                │
                    │    SSID: "Boi"                                                                     │
                    │    Network: 192.168.43.0/24                                       │
                    └──────────────┬──────────────────────┘
                                                          │
                                                          │
                    ┌──────────────▼──────────────────────┐
                    │         ESP32 Robot                                                             │
                    │  ┌──────────┐  ┌─────────────────────┐  │
                    │  │ WiFi                 │  │ Motor Control                          │ │
                    │  │ Station            │  │ L298N Driver                           │ │
                    │  └──────────┘  └─────────────────────┘ │
                    │  ┌──────────┐  ┌─────────────────────┐ │
                    │  │ UDP                │  │ PID Line                                     │ │
                    │  │ Listener         │  │ Following                                   │ │
                    │  └──────────┘  └─────────────────────┘ │
                    │  ┌─────────────────────────────────┐  │
                    │  │ Safety Timer (1.5s timeout)                               │  │
                    │  └─────────────────────────────────┘  │
                    └─────────────────────────────────────┘
```

---

## Core Components

### 1. Flutter Application (`lib/`)

**Key Files**:

- `pages/payment_page.dart` - Checkout with robot trigger
- `services/robot_api.dart` - UDP communication with retry and discovery
- `providers/cart_provider.dart` - State management with immutable models

See [Code Structure](./CODE_STRUCTURE.md) for complete file listing.

### 2. ESP32 Robot Firmware (`robots/`)

**Key Files**:

- `robots.ino` - Main program with WiFi, UDP listener, safety timeout
- `config.h` - WiFi credentials and pin configuration
- `motor_control.h` - PWM motor driver (L298N)
- `pid_control.h` - Line following algorithm

---

## Data Flow

### Order to Delivery Flow

```text
1. User browses products
        ↓
2. Adds items to cart
        ↓
3. Applies coupon (optional)
        ↓
4. Goes to Payment Page
        ↓
5. Selects delivery address
        ↓
6. Chooses payment method
        ↓
7. Clicks "ยืนยันรายการ" (Confirm)
        ↓
8. Flutter sends UDP "F" command ──────┐
        ↓                                                                       │
9. Shows success dialog                                    │
        ↓                                                                      │
10. Order saved to history                                │
                                                                                ▼
                                                          ESP32 receives "F"
                                                                      ↓
                                                          Moves robot FORWARD
                                                                      ↓
                                                          Safety timer starts (1.5s)
                                                                      ↓
                                                          If no new command in 1.5s → STOP
```

### Incoming Call Flow (Robot Arrival)

```text
1. Order completed (after 10 seconds)
        ↓
2. CartProvider triggers playNotificationSound()
        ↓
3. Incoming Call UI appears
        ↓
4. 180-second countdown starts
        ↓
5. User must click "รับสินค้า" (Receive)
        ↓
6. Order status → "สำเร็จ" (Complete)
        ↓
7. Rating dialog appears
```

---

## Network Communication

### Protocol: UDP (User Datagram Protocol)

| Aspect         | Value                            |
| -------------- | -------------------------------- |
| **Protocol**   | UDP                              |
| **Port**       | 2001                             |
| **Broadcast**  | 255.255.255.255 (with fallback)  |
| **Network**    | Phone WiFi Hotspot               |
| **Redundancy** | 3x packet resend with 50ms delay |

### Command Set

| Command | Action           | ESP32 Response                          |
| ------- | ---------------- | --------------------------------------- |
| `F`     | Move Forward     | Both motors forward at MAX_SPEED        |
| `B`     | Move Backward    | Both motors reverse at MAX_SPEED        |
| `L`     | Turn Left        | Left motor reverse, Right motor forward |
| `R`     | Turn Right       | Left motor forward, Right motor reverse |
| `S`     | Stop             | All motors stop                         |
| `LF`    | Line Follow Mode | Enable PID line following               |

### Safety Features

1. **Dead-Man's Switch**: Auto-stop after 1.5s without commands
2. **WiFi Reconnect**: Auto-reconnect if WiFi drops
3. **Emergency Stop**: Send `S` command anytime
4. **PID Reset**: Reset PID when entering line follow mode

---

## State Management

### CartProvider (Main State)

```dart
class CartProvider with ChangeNotifier {
  // Cart
  List<CartItem> _items;

  // Orders
  List<Order> _orders;

  // Coupons
  List<Coupon> _availableCoupons;
  Coupon? _appliedCoupon;

  // Robot
  bool _isIncomingCall;
  int _callTimeoutSeconds;
  int _currentTabIndex;
}
```

### Key States Tracked

- Cart items and quantities
- Order history with status
- Collected and applied coupons
- Robot incoming call status
- Call timeout countdown (180s)
- Active tab index

---

## Code Quality Standards

This codebase follows modern Dart/Flutter best practices (2024-2025):

- **Immutable State Management**: All model classes use final fields with copyWith patterns
- **Type-Safe Data**: Product class instead of map-based structures
- **Performance**: Proper const constructors throughout
- **Modern Patterns**: async/await instead of .catchError chains
- **DRY Principles**: Shared widgets extracted from duplicates
- **Collection Utilities**: firstWhereOrNull for safe list operations

Run `flutter analyze` to verify code quality.

---

Last Updated: 2026-04-07
