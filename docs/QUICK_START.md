# Quick Start Guide

Get your Boi delivery robot system up and running in 5 minutes.

---

## Prerequisites

### For Flutter App

- Flutter SDK 3.11.1 or higher
- Android Studio / VS Code with Flutter extensions
- Android device or emulator
- Dart SDK (included with Flutter)

### For ESP32 Robot

- ESP32 Development Board
- L298N Motor Driver (or compatible)
- 2x DC Motors
- Battery pack (7.4V-12V recommended)
- Arduino IDE with ESP32 support
- Micro USB cable

### For Network

- Smartphone with WiFi hotspot capability
- OR any 2.4GHz WiFi router

---

## Step-by-Step Setup

### Step 1: Set Up WiFi Hotspot

1. On your smartphone, go to **Settings > Hotspot & Tethering**
2. Turn on **WiFi Hotspot**
3. Configure:
   - **Network Name (SSID)**: `Boi`
   - **Password**: `12345678`
   - **Security**: WPA2
   - **Band**: 2.4GHz (ESP32 doesn't support 5GHz)

> ⚠️ **Important**: ESP32 only supports 2.4GHz WiFi networks!

---

### Step 2: Flash ESP32 Firmware

1. **Install Arduino IDE** (if not already installed)
   - Download from: [Arduino](https://www.arduino.cc/en/software)
   - Install ESP32 board support
     - Go to `Tools > Board > Boards Manager`
     - Search "ESP32" and install

2. **Open Firmware**
   - Open `robots/robots.ino` in Arduino IDE

3. **Configure Board**
   - `Tools > Board > ESP32 Dev Module`
   - `Tools > Upload Speed > 921600`
   - `Tools > Port > /dev/ttyUSB0` (or COMx on Windows)

4. **Upload**
   - Click the **Upload** button (→)
   - Wait for "Done uploading" message

5. **Verify Connection**
   - Open Serial Monitor (`Tools > Serial Monitor`)
   - Set baud rate to **115200**
   - You should see:

     ```
     Connecting to WiFi: Boi....
     WiFi Connected
     IP Address: 192.168.43.XXX
     Listening on UDP port 2001
     ===== ระบบพร้อมทำงาน =====
     ```

---

### Step 3: Run Flutter App

1. **Clone/Download Repository**

   ```bash
   cd /path/to/boi
   ```

2. **Install Dependencies**

   ```bash
   flutter pub get
   ```

3. **Connect Device**
   - Connect Android device via USB
   - Enable USB Debugging on device
   - Verify connection:

     ```bash
     flutter devices
     ```

4. **Run App**

```bash
   flutter run
   ```

---

### Step 4: Test Communication

1. **Ensure Both Devices on Same Network**
   - ESP32 connected to "Boi" hotspot ✅
   - Phone IS the "Boi" hotspot ✅

2. **Test from Flutter App**
   - Open the app
   - Add any product to cart
   - Go to cart and click "ชำระเงิน" (Payment)
   - Fill in delivery address
   - Select payment method
   - Click "ยืนยันรายการ" (Confirm)
   - Robot should move forward!

3. **Alternative: Test with Serial Monitor**
   - In Arduino Serial Monitor, you should see:

   ```
     Received UDP command: F
     ```

---

## Verification Checklist

- [ ] Phone hotspot is ON with SSID "Boi" and password "12345678"
- [ ] ESP32 successfully connected to WiFi (check Serial Monitor)
- [ ] ESP32 shows "Listening on UDP port 2001"
- [ ] Flutter app runs without errors
- [ ] Both devices on same network
- [ ] Sending "F" command makes robot move forward

---

## Troubleshooting

### ESP32 Won't Connect to WiFi

**Symptoms**: Stuck on "Connecting to WiFi: Boi...."

**Solutions**:

1. Verify hotspot is ON
2. Check password is exactly `12345678`
3. Ensure hotspot is broadcasting on **2.4GHz** (not 5GHz)
4. Move ESP32 closer to phone
5. Restart hotspot

### Robot Doesn't Move When Command Sent

**Symptoms**: App shows success, but robot doesn't move

**Check**:

1. Motors properly connected to L298N?
2. Battery charged and connected?
3. L298N enable pins receiving PWM?
4. Serial Monitor shows "Received UDP command: F"?

**Debug Steps**:

1. See [Debug Guide](./DEBUG_GUIDE.md) for full troubleshooting
2. Test with manual `netcat` command (Method 3 in Debug Guide)
3. Check motor wiring in [ESP32 Setup](./ESP32_SETUP.md)

### Flutter App Crashes on Startup

**Solutions**:

```bash
flutter clean
flutter pub get
flutter run
```

---

## First Order Walkthrough

1. **Launch App** → See splash screen, then home page
2. **Browse Products** → Scroll through categories
3. **Add to Cart** → Tap + button on any product
4. **View Cart** → Tap cart icon in bottom nav
5. **Apply Coupon** (optional) → Enter coupon code or collect from coupon page
6. **Checkout** → Tap "ชำระเงิน" button
7. **Select Address** → Choose Home or Office
8. **Choose Payment** → Select QR, Wallet, Card, or Cash
9. **Confirm** → Tap "ยืนยันรายการ"
10. **Success!** → Robot moves forward, order saved
11. **Wait for Delivery** → Robot arrives (simulated after 10s)
12. **Receive Order** → Tap "รับสินค้า" on incoming call screen
13. **Rate Experience** → Give 1-5 star rating

---

## Next Steps

After verifying basic functionality:

1. **Read** [System Overview](./SYSTEM_OVERVIEW.md) for architecture details
2. **Configure** [Network Setup](./NETWORK_SETUP.md) for custom networks
3. **Learn** [Debug Guide](./DEBUG_GUIDE.md) for troubleshooting
4. **Explore** [API Reference](./API_REFERENCE.md) for programmatic control

---

_Last Updated: 2026-04-06_
