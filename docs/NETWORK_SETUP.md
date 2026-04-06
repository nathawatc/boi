# Network Setup Guide

Complete guide to configuring network communication between Flutter app and ESP32 robot.

---

## 📡 Current Network Architecture

### Network Type: Phone WiFi Hotspot (Local Ad-Hoc Network)

```text
┌──────────────────────────────────────┐
│      Phone (Flutter App)                                                     │
│                                                                                                │
│  Creates Hotspot:                                                              │
│  • SSID: "Boi"                                                                      │
│  • Password: "12345678"                                               │
│  • Band: 2.4GHz                                                                 │
│  • IP: 192.168.43.1 (typical)                                          │
│  • Subnet: 255.255.255.0                                               │
└──────────────┬───────────────────────┘
                                      │
                                      │ WiFi Connection
                                      │
    ┌────────────▼──────────────────────┐
    │      ESP32 Robot                                                           │
    │                                                                                          │
    │  Mode: WIFI_STA (Station)                                      │
    │  IP: 192.168.43.XXX (DHCP)                                  │
    │  Listens: UDP Port 2001                                           │
    └───────────────────────────────────┘
```

---

## Default Configuration

### ESP32 Side (`robots/config.h`)

```cpp
const char* WIFI_SSID = "Boi";
const char* WIFI_PASSWORD = "12345678";
const uint16_t UDP_PORT = 2001;
```

### Flutter Side (`lib/services/robot_api.dart`)

```dart
RobotConfig config = RobotConfig(
  port: 2001,
  resendCount: 3,
  // ipAddress: null (auto-discovery via broadcast)
);
```

---

## Setting Up Phone Hotspot

### Android

1. **Open Settings**
   - Go to `Settings > Network & Internet > Hotspot & Tethering`
   - OR swipe down twice for Quick Settings, tap `Hotspot`

2. **Configure Hotspot**
   - Tap `Wi-Fi hotspot`
   - Set **Hotspot name**: `Boi`
   - Set **Password**: `12345678`
   - Set **Security**: `WPA2-Personal`
   - Set **Band**: `2.4 GHz` (⚠️ NOT 5 GHz!)

3. **Turn On**
   - Toggle `Wi-Fi hotspot` to ON
   - Note the IP address shown (usually `192.168.43.1`)

### iPhone (iOS)

1. **Open Settings**
   - Go to `Settings > Personal Hotspot`

2. **Configure**
   - Tap `Allow Others to Join`
   - Set **Wi-Fi Password**: `12345678`
   - Note: SSID will be your iPhone's name (e.g., "John's iPhone")

3. **Turn On**
   - Toggle `Allow Others to Join` to ON

> ⚠️ **iPhone Users**: You'll need to update ESP32 config to match your iPhone's hotspot name!

---

## Alternative: WiFi Router

If using a standard WiFi router instead of phone hotspot:

### Configuration

1. **Connect ESP32 to Router**

   ```cpp
   // In robots/config.h
   const char* WIFI_SSID = "YourRouterSSID";
   const char* WIFI_PASSWORD = "YourRouterPassword";
   ```

2. **Connect Phone to Same Router**
   - Phone must connect to the SAME WiFi network
   - Turn OFF mobile data to ensure WiFi is used

3. **Verify Both on Same Subnet**
   - ESP32 IP: Check Serial Monitor (e.g., `192.168.1.100`)
   - Phone IP: Check WiFi settings (e.g., `192.168.1.50`)
   - Both should start with same first 3 octets (e.g., `192.168.1.X`)

### Router Settings to Check

- ✅ **AP Isolation**: DISABLED (allows devices to communicate)
- ✅ **Client Isolation**: DISABLED
- ✅ **Firewall**: Allow local UDP on port 2001
- ✅ **Band**: 2.4GHz (ESP32 doesn't support 5GHz)

---

## Network Requirements

### Must Have

| Requirement            | Why                              | How to Check                                 |
| ---------------------- | -------------------------------- | -------------------------------------------- |
| **Same Network**       | UDP broadcast only works locally | Both devices get IP from same router/hotspot |
| **2.4GHz Band**        | ESP32 hardware limitation        | Check hotspot settings                       |
| **UDP Port 2001 Open** | Communication channel            | No firewall blocking                         |
| **No AP Isolation**    | Devices must see each other      | Router/hotspot settings                      |

### Optional but Recommended

| Feature                 | Benefit                            |
| ----------------------- | ---------------------------------- |
| **Static IP for ESP32** | Easier debugging                   |
| **Strong Signal**       | Better reliability                 |
| **Dedicated Network**   | No interference from other devices |

---

## Finding IP Addresses

### ESP32 IP

Check Arduino Serial Monitor after boot:

```text
WiFi Connected
IP Address: 192.168.43.156
```

### Phone IP

**Android**:

1. `Settings > About Phone > Status`
2. Look for `IP Address` under WiFi
3. OR use app: "WiFi Analyzer"

**iPhone**:

1. `Settings > WiFi`
2. Tap ⓘ next to connected network
3. Look for `IP Address`

**Expected Pattern**:

- Phone: `192.168.43.1` (hotspot creator)
- ESP32: `192.168.43.XXX` (DHCP client)

---

## Security Considerations

### Current State ⚠️

```cpp
// Hardcoded in config.h
const char* WIFI_SSID = "Boi";
const char* WIFI_PASSWORD = "12345678";
```

**Risks**:

- Anyone can connect to this network
- Credentials visible in source code
- No encryption on UDP commands

### Recommended Improvements

#### 1. Use WiFiManager (ESP32)

See `robots/wifi_manager_example.ino` for example:

```cpp
#include <WiFiManager.h>

WiFiManager wifiManager;

void setup() {
  // First time: Opens captive portal for WiFi config
  // Subsequent: Auto-connects to saved network
  wifiManager.autoConnect("Boi-Robot");
}
```

**Benefits**:

- ✅ No hardcoded credentials
- ✅ User configures via phone
- ✅ Saves to ESP32 EEPROM
- ✅ Works on any network

#### 2. Add Command Authentication

Future implementation:

```cpp
// ESP32 expects token with command
if (command.startsWith("F:") && verifyToken(token)) {
  moveForward();
}
```

---

## Network Troubleshooting

### Issue: ESP32 Won't Connect

**Symptoms**:

```text
Connecting to WiFi: Boi..............
(retries forever)
```

**Solutions**:

1. **Verify Hotspot is ON**
   - Check phone shows "Hotspot active"
   - Try connecting another device

2. **Check Password**
   - Must be EXACTLY `12345678`
   - Case sensitive!

3. **Check Band**
   - MUST be 2.4GHz
   - ESP32 CANNOT see 5GHz networks

4. **Move Closer**
   - ESP32 antenna is small
   - Keep within 3 meters

5. **Restart Everything**
   - Turn off hotspot
   - Restart ESP32
   - Turn on hotspot
   - Wait 30 seconds

---

### Issue: Commands Not Received

**Symptoms**:

- App shows "Command sent successfully"
- Serial Monitor shows nothing

**Solutions**:

1. **Verify Same Network**

   ```bash
   # On computer (if connected to same WiFi):
   ping 192.168.43.1  # Phone IP
   ping 192.168.43.XXX  # ESP32 IP
   ```

2. **Check Port**
   - Both must use port `2001`
   - Check `config.h` and `robot_api.dart`

3. **Test with netcat**

   ```bash
   echo -n "F" | nc -u -w1 192.168.43.XXX 2001
   ```

4. **Check Firewall**
   - Phone firewall may block outgoing UDP
   - Router may block broadcast
   - Try direct IP instead of broadcast

---

### Issue: Intermittent Connection

**Symptoms**:

- Works sometimes, fails others
- Random dropouts

**Solutions**:

1. **Check Signal Strength**
   - Serial Monitor shows RSSI:

     ```cpp
     Serial.println(WiFi.RSSI());
     ```

   - Should be > -70 dBm
   - -50 is excellent, -90 is unusable

2. **Reduce Interference**
   - Move away from microwave ovens
   - Avoid crowded 2.4GHz channels
   - Use hotspot instead of router

3. **Increase Redundancy**

   ```dart
   // In robot_api.dart
   RobotConfig config = RobotConfig(
     resendCount: 5, // Increase from 3
   );
   ```

---

## Network Performance

### Expected Metrics

| Metric                   | Good      | Poor      |
| ------------------------ | --------- | --------- |
| **Ping (Phone → ESP32)** | < 50ms    | > 200ms   |
| **UDP Success Rate**     | > 95%     | < 80%     |
| **WiFi RSSI**            | > -60 dBm | < -80 dBm |
| **Connection Time**      | < 3s      | > 10s     |

### Testing Network

```bash
# From computer on same network:
ping 192.168.43.XXX  # ESP32 IP

# Test UDP port:
nc -u 192.168.43.XXX 2001
# Type: F
# ESP32 should respond
```

---

## Future Network Improvements

### 1. TCP Fallback

- Add TCP connection for reliable commands
- Keep UDP for low-latency control
- Auto-switch based on reliability

### 2. MQTT Integration

- Use MQTT for command queueing
- Support offline message delivery
- Better for cloud integration

### 3. Bluetooth Fallback

- Use BLE when WiFi unavailable
- Short range but reliable
- No network infrastructure needed

---

## Related Documentation

- [Debug Guide](./DEBUG_GUIDE.md) - Test network communication
- [System Overview](./SYSTEM_OVERVIEW.md) - Architecture details

---

_Last Updated: 2026-04-06_
