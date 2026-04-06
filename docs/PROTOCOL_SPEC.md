# Boi Network Protocol Specification

## Overview

UDP-based communication between Flutter mobile app (controller) and ESP32 robot (actor).

## Network Configuration

| Parameter | Value                                                   |
| --------- | ------------------------------------------------------- |
| UDP Port  | 2001                                                    |
| Protocol  | UDP (fire-and-forget + optional response)               |
| Transport | WiFi hotspot (phone creates, ESP32 connects as station) |
| Subnet    | Typical /24 (e.g., 192.168.43.0/24)                     |

## Command Codes (6 Total)

| Code | Meaning     | ESP32 Action                            | Response |
| ---- | ----------- | --------------------------------------- | -------- |
| `F`  | Forward     | Move both motors forward at MAX_SPEED   | `F`      |
| `B`  | Backward    | Move both motors backward at MAX_SPEED  | `B`      |
| `L`  | Turn Left   | Left motor reverse, right motor forward | `L`      |
| `R`  | Turn Right  | Left motor forward, right motor reverse | `R`      |
| `S`  | Stop        | Stop all motors                         | `S`      |
| `LF` | Line Follow | Enable PID line-follow mode             | `LF`     |

Any other command → ESP32 responds with `ERR` and ignores it.

## Protocol Flows

### 1. Robot Discovery

```text
Flutter                                ESP32
  |                                      |
  |-- UDP "S" x3 (broadcast:2001) ------>|  (send 100ms apart)
  |                                      |
  |<-- UDP "S" (ephemeral_port) --------|  (immediate response)
  |                                      |
  |--- timeout (2s) ---|                 |  (if no response)
  |                                      |
  Result: IP = ESP32's source IP         |
```

**Critical**: Flutter MUST start listening (socket.listen) BEFORE sending discovery packets, otherwise responses are lost.

### 2. Command Send

```text
Flutter                                ESP32
  |                                      |
  |-- UDP "F" x3 (robot_ip:2001) ------>|  (send 50ms apart)
  |                                      |
  |<-- UDP "F" (ephemeral_port) --------|  (1 response per received packet)
  |<-- UDP "F" (ephemeral_port) --------|  (may receive 3 responses)
  |<-- UDP "F" (ephemeral_port) --------|
  |                                      |
  Result: success (fire-and-forget)      |
  (no response validation in Flutter)    |
```

**Note**: Flutter does NOT wait for or validate command responses. Commands are fire-and-forget. The 3x resend compensates for UDP packet loss.

### 3. Multi-Robot Discovery

```text
Flutter                                ESP32 #1
  |                                      |
  |-- UDP "S" x5 (broadcast:2001) ------>|
  |<-- UDP "S" (ephemeral) <-------------|
  |                                      |
  |                                      | ESP32 #2
  |<-- UDP "S" (ephemeral) <-------------|
  |                                      |
  |--- timeout (3s) ---|                 |
  Result: [ip1, ip2]                     |
```

## Safety Mechanisms

### Dead-Man's Switch (1.5S Timeout)

ESP32 tracks `lastCommandTime`. If no command received for 1500ms and robot is in manual mode, motors stop automatically.

### Obstacle Detection (30Cm)

ESP32 checks ultrasonic sensor every 200ms. If obstacle < 30cm detected while moving, motors stop immediately.

### WiFi Auto-Reconnect

ESP32 checks WiFi every 5s. If disconnected, re-associates with up to 3s wait, then restarts UDP listener.

## Packet Format

- **Payload**: Raw ASCII string (e.g., "F", "S", "LF")
- **Encoding**: UTF-8 compatible (codeUnits in Dart = ASCII subset)
- **Max size**: 254 bytes (ESP32 buffer is 255 with null terminator)
- **No header/footer**: Just the command string
- **No checksum**: UDP reliability compensated by 3x resend

## Port Assignment

| Role                         | Port          | Notes                           |
| ---------------------------- | ------------- | ------------------------------- |
| ESP32 listener               | 2001          | Fixed, defined in config.h      |
| Flutter sender               | ephemeral (0) | OS-assigned, unique per socket  |
| Flutter listener (discovery) | ephemeral (0) | OS-assigned, response goes here |

## Flutter Redundancy

- Discovery: 3 packets, 100ms apart
- Commands: 3 packets, 50ms apart
- Multi-discovery: 5 packets, 100ms apart

## ESP32 Response Behavior

- Responds to EVERY valid UDP packet (including redundant ones)
- Response = exact command code echo
- Response port = sender's source port (from UDP header)
- No response for unknown commands (sends "ERR" instead)
