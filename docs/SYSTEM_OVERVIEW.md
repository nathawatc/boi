# System Overview

## What is Boi?

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

#### Pages

- **`pages/home_page.dart`** - Main screen with products, categories, promotions
- **`pages/cart_page.dart`** - Shopping cart with coupon support
- **`pages/payment_page.dart`** - Checkout with address, payment method, robot trigger
- **`pages/order_history_page.dart`** - Order tracking and history
- **`pages/order_detail_page.dart`** - Individual order details
- **`pages/coupon_page.dart`** - Coupon collection and management
- **`pages/product_detail_page.dart`** - Product information and add to cart
- **`pages/category_products_page.dart`** - Products by category
- **`pages/splash_screen.dart`** - App loading screen

#### Services

- **`services/robot_api.dart`** - UDP communication service (NEW)
  - Command sending with retry (3x redundancy)
  - Connection status tracking
  - Robot discovery
  - Error handling

#### Providers

- **`providers/cart_provider.dart`** - State management
  - Cart items management
  - Order creation and tracking
  - Coupon collection and application
  - Incoming call simulation (notification sound + timer)

#### Widgets

- Custom UI components for products, coupons, categories, etc.
- **`widgets/incoming_call_widget.dart`** - Robot arrival notification

### 2. ESP32 Robot Firmware (`robots/`)

#### Files

- **`robots.ino`** - Main program
  - WiFi connection (Station mode)
  - UDP command processing
  - Safety timeout (1.5s dead-man's switch)
  - Auto-reconnect WiFi

- **`config.h`** - Configuration
  - WiFi credentials (SSID: "Boi", Password: "12345678")
  - Motor pins (L298N driver)
  - Sensor pins (Ultrasonic, Line tracking)
  - PID parameters

- **`motor_control.h`** - Motor driver
  - PWM control for 2 DC motors
  - Forward/Reverse/Stop
  - Speed control (0-255)

- **`pid_control.h`** - Line following
  - PID algorithm for autonomous navigation
  - 3-sensor line tracking
  - Error calculation and correction

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

## UI/UX Features

### Completed

- ✅ Product browsing with categories
- ✅ Horizontal scrollable promotions
- ✅ Shopping cart with quantity control
- ✅ Coupon collection system
- ✅ Payment page with address selection
- ✅ Order history with status tracking
- ✅ Incoming call notification UI
- ✅ Rating dialog after delivery
- ✅ Loading states and error dialogs
- ✅ Robot connection status indicator
- ✅ Manual robot control page

### In Progress

- ⏳ Real-time order tracking on map

---

## Security Considerations

### Current State

- ⚠️ Hardcoded WiFi credentials in ESP32
- ⚠️ No authentication in Flutter app
- ⚠️ UDP commands unencrypted
- ✅ No sensitive data in Flutter

### Recommended Improvements

- Implement WiFiManager for ESP32 (see `wifi_manager_example.ino`)
- Add command authentication (e.g., token-based)
- Use TCP for critical commands
- Add user authentication for app

---

## Performance Metrics

### UDP Communication

- **Latency**: ~10-50ms (local network)
- **Packet Loss**: ~5-10% (mitigated by 3x resend)
- **Effective Success Rate**: >99% with redundancy

### Flutter App

- **Startup Time**: ~3 seconds (splash screen)
- **Page Transitions**: <200ms
- **Cart Operations**: Instant (<50ms)

### ESP32 Robot

- **WiFi Connection**: 2-5 seconds
- **Command Processing**: <10ms
- **Motor Response**: ~100ms
- **PID Loop**: 10ms intervals

---

## Future Enhancements

### Short Term

1. **WiFiManager Integration** - Dynamic WiFi configuration via captive portal
2. **Robot Control Page** - Manual F/B/L/R/S controls in app
3. **Connection Status** - Real-time robot online/offline indicator
4. **Command Acknowledgment** - ESP32 sends response back to app

### Medium Term

1. **Battery Monitoring** - Show robot battery level in app
2. **Multiple Robot Support** - Control fleet of robots
3. **Delivery Route Planning** - Optimize delivery paths
4. **Order Queue** - Multiple pending orders handling

### Long Term

1. **Autonomous Navigation** - Full SLAM with sensors
2. **Mobile App Analytics** - Track user behavior
3. **Push Notifications** - Real-time order updates
4. **Multi-language Support** - Beyond Thai

---

## Related Documentation

- [Network Setup](./NETWORK_SETUP.md) - WiFi configuration
- [Debug Guide](./DEBUG_GUIDE.md) - Troubleshooting
- [API Reference](./API_REFERENCE.md) - Robot API documentation

---

_Last Updated: 2026-04-06_
