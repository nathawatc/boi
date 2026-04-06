# Code Structure

Understanding the organization and architecture of the Boi delivery robot codebase.

---

## Project Structure Overview

```text
boi/
├── lib/                          # Flutter application source
│   ├── main.dart                 # App entry point
│   │
│   ├── pages/                    # UI Screens
│   │   ├── home_page.dart        # Main screen with products
│   │   ├── cart_page.dart        # Shopping cart
│   │   ├── payment_page.dart     # Checkout & robot trigger
│   │   ├── order_history_page.dart  # Order list
│   │   ├── order_detail_page.dart   # Order details
│   │   ├── coupon_page.dart      # Coupon management
│   │   ├── product_detail_page.dart  # Product info
│   │   ├── category_products_page.dart  # Products by category
│   │   └── splash_screen.dart    # Loading screen
│   │
│   ├── services/                 # Business Logic Services
│   │   └── robot_api.dart        # UDP robot communication ⭐
│   │
│   ├── providers/                # State Management
│   │   └── cart_provider.dart    # Cart, orders, coupons, robot state
│   │
│   ├── widgets/                  # Reusable UI Components
│   │   ├── custom_search_bar.dart
│   │   ├── product_card.dart
│   │   ├── frequent_product_item.dart
│   │   ├── category_item.dart
│   │   ├── promotion_item.dart
│   │   ├── coupon_card.dart
│   │   ├── section_header.dart
│   │   ├── rating_dialog.dart
│   │   ├── delivery_toggle.dart
│   │   ├── action_item.dart
│   │   └── incoming_call_widget.dart  # Robot arrival UI
│   │
│   └── theme/                    # Styling
│       └── app_theme.dart        # Colors, gradients, text styles
│
├── robots/                       # ESP32 Robot Firmware
│   ├── robots.ino                # Main firmware program
│   ├── config.h                  # Configuration (WiFi, pins, PID)
│   ├── motor_control.h           # Motor driver (L298N)
│   ├── pid_control.h             # Line following algorithm
│   └── wifi_manager_example.ino  # Dynamic WiFi config example
│
├── docs/                         # Documentation ⭐
│   ├── README.md                 # Documentation index
│   ├── QUICK_START.md            # 5-minute setup guide
│   ├── SYSTEM_OVERVIEW.md        # Architecture & features
│   ├── NETWORK_SETUP.md          # WiFi configuration
│   ├── DEBUG_GUIDE.md            # Troubleshooting
│   ├── API_REFERENCE.md          # Robot API docs
│   ├── CODE_STRUCTURE.md         # This file
│   ├── ESP32_SETUP.md            # Firmware installation
│   └── ROBOT_ASSEMBLY.md         # Hardware guide
│
├── assets/                       # Static Resources
│   ├── images/                   # App images
│   │   ├── Logo.JPG
│   │   └── banner[1-4].png
│   └── sounds/                   # Audio files
│       └── notification.mp3      # Robot arrival sound
│
├── test/                         # Unit & Widget Tests
│   └── widget_test.dart          # Basic app test
│
├── android/                      # Android-specific files
├── ios/                          # iOS-specific files
├── web/                          # Web build files
│
├── pubspec.yaml                  # Flutter dependencies
├── analysis_options.yaml         # Linter rules
└── README.md                     # Project README
```

---

## Architecture Layers

### Layer 1: Presentation (UI)

**Location**: `lib/pages/` and `lib/widgets/`

**Purpose**: User interface and interaction

**Key Files**:

```dart
// Full screens
pages/home_page.dart          // Entry point after splash
pages/payment_page.dart       // Triggers robot movement
pages/order_history_page.dart // Shows order status

// Reusable components
widgets/product_card.dart     // Product display
widgets/incoming_call_widget.dart  // Robot arrival screen
```

**Pattern**:

- Pages are full screens
- Widgets are reusable components
- Both use Provider for state access

---

### Layer 2: State Management

**Location**: `lib/providers/`

**Purpose**: Centralized app state

**Key File**:

```dart
providers/cart_provider.dart
```

**Manages**:

- Cart items
- Order history
- Coupons (collected & applied)
- Robot incoming call state
- Tab navigation index

**Pattern**: ChangeNotifier with Provider

**Usage**:

```dart
// In widget
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Text('Items: ${cart.itemCount}');
  }
}
```

---

### Layer 3: Services (Business Logic)

**Location**: `lib/services/`

**Purpose**: External communication and complex operations

**Key File**:

```dart
services/robot_api.dart  // ⭐ NEW
```

**Responsibilities**:

- UDP packet creation and sending
- Connection status tracking
- Error handling
- Robot discovery

**Pattern**: Service class with ChangeNotifier for status

**Usage**:

```dart
final robotApi = RobotApi();
await robotApi.moveForward();
```

---

### Layer 4: Firmware (Hardware)

**Location**: `robots/`

**Purpose**: ESP32 robot control

**Key Files**:

```cpp
robots.ino           // Main loop, WiFi, UDP listener
config.h             // All configuration
motor_control.h      // PWM motor control
pid_control.h        // Line following
```

**Pattern**: Arduino-style setup() and loop()

---

## Data Flow

### Example: User Places Order

```text
┌─────────────────────────────────────────────────────────────┐
│ 1. USER INTERACTION (Presentation Layer)                                                                       │
│    - User clicks "ยืนยันรายการ" on PaymentPage                                                                    │
└──────────────────┬──────────────────────────────────────────┘
                                                │
                                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. STATE ACCESS (State Management)                                                                                  │
│    - Gets cartProvider reference                                                                                                │
│    - Reads cart items for order                                                                                                    │
└──────────────────┬──────────────────────────────────────────┘
                                                │
                                                ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. ROBOT COMMAND (Service Layer)                                                                                     │
│    - robotApi.moveForward() called                                                                                          │
│    - UDP packet "F" created                                                                                                        │
│    - Sent 3x to broadcast address 255.255.255.255:2001                                               │
└──────────────────┬──────────────────────────────────────────┘
                                                │
                                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. NETWORK (WiFi Hotspot)                                                                                                     │
│    - Packet travels over phone's hotspot                                                                                 │
│    - ESP32 receives on UDP port 2001                                                                                    │
└──────────────────┬──────────────────────────────────────────┘
                                                │
                                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. FIRMWARE (ESP32)                                                                                                               │
│    - robots.ino processes command                                                                                         │
│    - motor_control.h drives motors                                                                                           │
│    - Robot moves forward                                                                                                            │
└──────────────────┬──────────────────────────────────────────┘
                                                │
                                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. STATE UPDATE (State Management)                                                                                  │
│    - cartProvider.checkout() called                                                                                            │
│    - Cart cleared                                                                                                                              │
│    - Order created and added to history                                                                                   │
│    - Timer started for incoming call (10s delay)                                                                     │
└──────────────────┬──────────────────────────────────────────┘
                                                │
                                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 7. UI UPDATE (Presentation Layer)                                                                                         │
│    - Success dialog shown                                                                                                           │
│    - Navigate to order history                                                                                                      │
│    - After 10s: Incoming call widget appears                                                                         │
└─────────────────────────────────────────────────────────────┘
```

---

## Key Design Patterns

### 1. Provider Pattern

**Where**: State management

**Why**: Simple, built-in to Flutter

**Example**:

```dart
// Provider definition
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => CartProvider()),
  ],
  child: BoiApp(),
)

// Usage
context.watch<CartProvider>().items;
context.read<CartProvider>().addItem(...);
```

---

### 2. Service Layer Pattern

**Where**: Robot API

**Why**: Separation of concerns, testability

**Example**:

```dart
// Service encapsulated in separate file
class RobotApi extends ChangeNotifier {
  Future<RobotResponse> moveForward() async {
    // Complex UDP logic hidden from UI
  }
}

// UI only calls simple method
await RobotApi().moveForward();
```

---

### 3. Observer Pattern

**Where**: Connection status updates

**Why**: Reactive UI updates

**Example**:

```dart
// RobotApi notifies listeners on status change
class RobotApi extends ChangeNotifier {
  void _updateStatus(RobotConnectionStatus status) {
    _connectionStatus = status;
    notifyListeners();  // Triggers rebuild
  }
}

// UI listens for changes
ListenableBuilder(
  listenable: robotApi,
  builder: (context, child) {
    return Text('Status: ${robotApi.connectionStatus}');
  },
)
```

---

### 4. Command Pattern

**Where**: Robot commands

**Why**: Type safety, extensibility

**Example**:

```dart
// Commands as enum
enum RobotCommand {
  forward('F'),
  backward('B'),
  // ...
}

// Usage prevents typos
await robotApi.sendCommand(RobotCommand.forward);  // ✅
await robotApi.sendCommand("F");                   // ❌ Not allowed
```

---

## Dependencies Graph

```text
main.dart
  ├── CartProvider (state)
  │   ├── Cart items
  │   ├── Orders
  │   ├── Coupons
  │   └── Robot state
  │
  └── Pages
      ├── HomePage
      │   ├── ProductCard (widget)
      │   ├── CategoryItem (widget)
      │   └── CouponCard (widget)
      │
      ├── PaymentPage
      │   └── RobotApi (service) ⭐
      │       └── UDP Communication
      │
      └── OrderHistoryPage
          └── Uses CartProvider.orders
```

---

## State Management Deep Dive

### CartProvider Structure

```dart
class CartProvider with ChangeNotifier {
  // ========== DATA ==========
  final List<CartItem> _items = [];
  final List<Order> _orders = [];
  final List<Coupon> _availableCoupons = [...];

  Coupon? _appliedCoupon;
  int _currentTabIndex = 0;
  bool _isIncomingCall = false;
  int _callTimeoutSeconds = 180;

  // ========== COMPUTED ==========
  int get itemCount => ...
  double get subTotal => ...
  double get totalAmount => ...
  List<Coupon> get collectedCoupons => ...

  // ========== ACTIONS ==========
  void addItem(String id, String name, String price, {int quantity});
  void removeItem(String id);
  void checkout();
  bool applyCoupon(String code);
  void collectCoupon(String code);
  void setTabIndex(int index);
  void confirmOrderReceipt(String orderId);

  // ========== ROBOT ==========
  void playNotificationSound({bool isLong});
  void stopCall();
}
```

---

## Theme Structure

**Location**: `lib/theme/app_theme.dart`

```dart
class AppTheme {
  // Colors
  static const Color primaryGreen = Color(0xFF00A651);
  static const Color primarySky = Color(0xFF87CEEB);
  static const Color gradientEnd = Color(0xFF005699);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(...);

  // Theme
  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryGreen,
    // ...
  );
}
```

**Usage**:

```dart
// Consistent colors across app
color: AppTheme.primaryGreen,
decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
```

---

## Testing Structure

```text
test/
└── widget_test.dart          # Basic smoke test
```

**Current Coverage**:

- ✅ App instantiation
- ✅ CartProvider creation/disposal

**Future Tests Needed**:

- Cart operations (add/remove/checkout)
- Coupon application
- Robot API methods
- Order creation
- Payment flow

---

## Configuration Files

### `pubspec.yaml`

- App metadata
- Dependencies
- Asset declarations
- Build configuration

### `analysis_options.yaml`

- Linter rules
- Code quality settings

### `android/` & `ios/`

- Platform-specific configs
- Permissions (network, storage)
- Build settings

---

## Entry Points

### Flutter App

```dart
// lib/main.dart
void main() {
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartProvider()),
        ],
        child: const BoiApp(),
      ),
    ),
  );
}
```

### ESP32 Firmware

```cpp
// robots/robots.ino
void setup() {
  Serial.begin(115200);
  initMotors();
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  udp.begin(UDP_PORT);
}

void loop() {
  // Process UDP commands
  // Update PID line following
  // Safety timeout checks
}
```

---

## Naming Conventions

### Dart/Flutter

- **Files**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Variables**: `camelCase`
- **Constants**: `camelCase` (Dart convention)
- **Private**: `_leadingUnderscore`

### ESP32/Arduino

- **Files**: `snake_case.h/.ino`
- **Constants**: `UPPER_SNAKE_CASE`
- **Variables**: `camelCase`
- **Functions**: `camelCase`

---

## Related Documentation

- [System Overview](./SYSTEM_OVERVIEW.md) - Features and architecture
- [API Reference](./API_REFERENCE.md) - Robot API usage
- [Quick Start](./QUICK_START.md) - Get running fast

---

_Last Updated: 2026-04-06_
