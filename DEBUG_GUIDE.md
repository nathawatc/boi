# Robot UDP Communication - Debug & Verification Guide

This guide explains how to test and debug the UDP communication between the
**Flutter Application** and the **ESP32 Robot**.

## Prerequisites

For the system to work, **both** the device running the Flutter app
(smartphone/emulator) and the ESP32
**must be connected to the exact same WiFi network**.

Based on your `config.h`, the default network is:

- **SSID (WiFi Name):** `Boi`
- **Password:** `12345678`

---

## Method 1: Full System Test (App + Robot)

*Use this when you have both the Flutter app and the physical ESP32 ready.*

1. **Start the Network:** Turn on a mobile hotspot with SSID `Boi` and password `12345678`.
2. **Boot the ESP32:**
   - Connect the ESP32 to your computer.
   - Open the Arduino IDE Serial Monitor (Baud Rate: `115200`).
   - Wait for the ESP32 to connect to WiFi. You should see:

     ```text
     Connecting to WiFi: Boi....
     WiFi Connected
     IP Address: 192.168.x.x
     Listening on UDP port 2001
     ===== ระบบพร้อมทำงาน =====
     ```

3. **Run the Flutter App:** Make sure the phone/emulator is connected to the `Boi` hotspot.
4. **Trigger the Event:** Go to the Payment Page and press **"ยืนยันรายการ"**.
5. **Verify:**
   - In the **Flutter Console**, you should see: `Successfully sent UDP packet "F" to Robot (Broadcast 2001)`
   - In the **Arduino Serial Monitor**, you should see: `Received UDP command: F` and the robot's motors should start moving.

---

## Method 2: Test Flutter App (Without Robot)

*Use this to verify the Flutter app is successfully broadcasting UDP packets,
even if the robot is turned off.*

1. Connect your computer to the same WiFi network as your phone/emulator.
2. Create a file on your computer named `test_server.py` with the following Python code:

   ```python
   import socket

   # Listen on all IPs, port 2001 (UDP)
   sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
   sock.bind(('', 2001))

   print("Mock Robot is listening for UDP packets on port 2001...")

   while True:
       data, addr = sock.recvfrom(1024)
       print(f"Received command: '{data.decode()}' from {addr}")
   ```

3. Run the script in your computer's terminal:

   ```bash
   python test_server.py
   ```

4. Press **"ยืนยันรายการ"** in the Flutter app.
5. You should see the terminal print the received `"F"` command along with your phone's IP address.

---

## Method 3: Test Robot (Without Flutter App)

*Use this to test the ESP32 logic and motor controls without needing the Flutter
app.*

1. Connect your computer to the `Boi` WiFi network.
2. Get the ESP32's IP address from the Arduino Serial Monitor (e.g., `192.168.43.100`).
3. Open your computer's terminal (Linux/macOS) and use `netcat` (`nc`) to send UDP packets:

   **Move Forward:**

   ```bash
   echo -n "F" | nc -u -w1 <ESP32_IP_ADDRESS> 2001
   ```

   **Enable Line Follow (PID) Mode:**

   ```bash
   echo -n "LF" | nc -u -w1 <ESP32_IP_ADDRESS> 2001
   ```

   **Stop:**

   ```bash
   echo -n "S" | nc -u -w1 <ESP32_IP_ADDRESS> 2001
   ```

*(Replace `<ESP32_IP_ADDRESS>` with the actual IP address of the robot).*

---

## Troubleshooting Common Issues

- **App says packet sent, but robot does nothing:**
  - Verify they are on the exact same WiFi network.
  - Some public routers or strict corporate WiFis enable "AP Isolation" or "Client Isolation", which blocks devices from talking to each other. Use a standard mobile hotspot to test.
- **ESP32 is stuck on `Connecting to WiFi: Boi....`:**
  - Ensure your hotspot is turned on, broadcasting at 2.4GHz (ESP32 does not support 5GHz), and the password is exactly `12345678`.
- **Motors make a humming sound but don't spin:**
  - Check your power supply. The ESP32 cannot power DC motors directly from its 3.3V or 5V pins reliably; ensure you have a proper battery pack connected to your motor driver (L298N, TB6612, etc.).
