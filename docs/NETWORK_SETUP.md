# Network Setup Guide

Complete guide to configuring network communication between Flutter app and ESP32 robot.

---

## Network Architecture

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

## Setting up Phone Hotspot

### Android

1. Go to `Settings > Network & Internet > Hotspot & Tethering`
2. Set **Hotspot name**: `Boi`, **Password**: `12345678`
3. Set **Band**: `2.4 GHz` (IMPORTANT: NOT 5 GHz!)
4. Toggle hotspot ON and note the IP (usually `192.168.43.1`)

### iPhone

1. Go to `Settings > Personal Hotspot`
2. Toggle `Allow Others to Join` ON
3. Set **Wi-Fi Password**: `12345678`

> **NOTE**: SSID will be your iPhone's name. Update ESP32 config to match!

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

- **AP Isolation**: DISABLED (allows devices to communicate)
- **Client Isolation**: DISABLED
- **Firewall**: Allow local UDP on port 2001
- **Band**: 2.4GHz (ESP32 doesn't support 5GHz)

---

## Network Requirements

### Must Have

| Requirement            | Why                              | How to Check                                 |
| ---------------------- | -------------------------------- | -------------------------------------------- |
| **Same Network**       | UDP broadcast only works locally | Both devices get IP from same router/hotspot |
| **2.4GHz Band**        | ESP32 hardware limitation        | Check hotspot settings                       |
| **UDP Port 2001 Open** | Communication channel            | No firewall blocking                         |
| **No AP Isolation**    | Devices must see each other      | Router/hotspot settings                      |

### Finding IP Addresses

**ESP32 IP**: Check Arduino Serial Monitor after boot.

**Phone IP**:

- **Android**: `Settings > About Phone > Status` or use "WiFi Analyzer" app
- **iPhone**: `Settings > WiFi` > tap ⓘ next to connected network

**Expected Pattern**: Phone `192.168.43.1`, ESP32 `192.168.43.XXX`

---

## Security Considerations

See [Security section in System Overview](./SYSTEM_OVERVIEW.md).

---

## Network Troubleshooting

See [Debug Guide](./DEBUG_GUIDE.md) for comprehensive troubleshooting.

**Quick checks**:

- Verify hotspot is ON and 2.4GHz
- Password must be exactly `12345678`
- Both devices on same network
- Test with: `echo -n "F" | nc -u -w1 <ESP32_IP> 2001`

---

## Network Performance

### Expected Metrics

| Metric                    | Good      | Poor      |
| ------------------------- | --------- | --------- |
| **Ping (Phone to ESP32)** | < 50ms    | > 200ms   |
| **UDP Success Rate**      | > 95%     | < 80%     |
| **WiFi RSSI**             | > -60 dBm | < -80 dBm |
| **Connection Time**       | < 3s      | > 10s     |

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

Last Updated: 2026-04-07
