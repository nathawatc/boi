# Robot API Reference

Complete documentation for the `RobotApi` service layer that handles communication between Flutter app and ESP32 robot.

---

## Location

```text
lib/services/robot_api.dart
```

---

## Overview

The `RobotApi` service provides a clean, type-safe interface for sending commands to the ESP32 robot via UDP. It handles
connection tracking, error handling, and automatic broadcast address detection.

---

## Classes

### 1. RobotCommand (Enum)

Type-safe robot commands.

```dart
enum RobotCommand {
  forward('F'),
  backward('B'),
  left('L'),
  right('R'),
  stop('S'),
  lineFollow('LF');

  final String value;
}
```

#### Usage

```dart
// Access command value
RobotCommand.forward.value  // Returns: "F"

// Use in sendCommand
await robotApi.sendCommand(RobotCommand.forward);
```

---

### 2. RobotConnectionStatus (Enum)

Tracks connection state with robot.

```dart
enum RobotConnectionStatus {
  disconnected,  // Not connected
  connecting,    // Attempting connection
  connected,     // Successfully connected
  error,         // Connection failed
}
```

#### Usage

```dart
if (robotApi.connectionStatus == RobotConnectionStatus.connected) {
  // Safe to send commands
}
```

---

### 3. RobotConfig

Configuration for robot connection.

```dart
class RobotConfig {
  final String? ipAddress;  // null = auto-discovery
  final int port;
  final Duration timeout;
  final int resendCount;

  const RobotConfig({
    this.ipAddress,
    this.port = 2001,
    this.timeout = const Duration(seconds: 2),
    this.resendCount = 3,
  });

  static const defaults = RobotConfig();
}
```

#### Parameters

| Parameter     | Type       | Default     | Description                                             |
| ------------- | ---------- | ----------- | ------------------------------------------------------- |
| `ipAddress`   | `String?`  | `null`      | Direct IP of robot. If `null`, uses broadcast discovery |
| `port`        | `int`      | `2001`      | UDP port number                                         |
| `timeout`     | `Duration` | `2 seconds` | Timeout for operations                                  |
| `resendCount` | `int`      | `3`         | Number of times to resend command for reliability       |

#### Usage Examples

```dart
// Default configuration
const config = RobotConfig.defaults;

// Custom IP
const config = RobotConfig(
  ipAddress: '192.168.43.100',
  port: 2001,
);

// High reliability
const config = RobotConfig(
  resendCount: 5,
  timeout: Duration(seconds: 5),
);
```

---

### 4. RobotResponse

Response from robot after command.

```dart
class RobotResponse {
  final bool success;
  final String message;
  final DateTime timestamp;

  factory RobotResponse.successInstance() => ...
  factory RobotResponse.errorInstance(String message) => ...
}
```

#### Properties

| Property    | Type       | Description                           |
| ----------- | ---------- | ------------------------------------- |
| `success`   | `bool`     | Whether command was sent successfully |
| `message`   | `String`   | Human-readable status message         |
| `timestamp` | `DateTime` | When response was created             |

#### Usage

```dart
final response = await robotApi.moveForward();

if (response.success) {
  print('SUCCESS: ${response.message}');
} else {
  print('FAILED: ${response.message}');
}
```

---

### 5. RobotApi (Main Service Class)

Main service class for robot communication.

```dart
class RobotApi extends ChangeNotifier {
  // Properties
  RobotConnectionStatus connectionStatus;
  String? lastKnownIp;
  bool isConnected;

  // Methods
  Future<RobotResponse> sendCommand(RobotCommand command, {RobotConfig? config});
  Future<String?> discoverRobot({Duration? timeout});
  void configure(RobotConfig config);
  void reset();

  // Convenience methods
  Future<RobotResponse> moveForward({RobotConfig? config});
  Future<RobotResponse> moveBackward({RobotConfig? config});
  Future<RobotResponse> turnLeft({RobotConfig? config});
  Future<RobotResponse> turnRight({RobotConfig? config});
  Future<RobotResponse> stop({RobotConfig? config});
  Future<RobotResponse> enableLineFollow({RobotConfig? config});
}
```

---

## Methods

### sendCommand()

Send any command to robot.

**Signature**:

```dart
Future<RobotResponse> sendCommand(
  RobotCommand command, {
  RobotConfig? config,
})
```

**Parameters**:

- `command`: The command to send
- `config`: Optional custom configuration

**Returns**: `RobotResponse` with success status

**Example**:

```dart
final response = await robotApi.sendCommand(RobotCommand.forward);
```

**Internal Process**:

1. Sets status to `connecting`
2. Determines target IP (from config, last known, or broadcast)
3. Creates UDP socket
4. Sends command `resendCount` times with 50ms delay
5. Updates status to `connected` on success
6. Returns response

---

### Convenience Methods

Shortcut methods for common commands.

#### moveForward()

```dart
Future<RobotResponse> moveForward({RobotConfig? config})
```

**Example**:

```dart
await robotApi.moveForward();
```

---

#### moveBackward()

```dart
Future<RobotResponse> moveBackward({RobotConfig? config})
```

**Example**:

```dart
await robotApi.moveBackward();
```

---

#### turnLeft()

```dart
Future<RobotResponse> turnLeft({RobotConfig? config})
```

**Example**:

```dart
await robotApi.turnLeft();
```

---

#### turnRight()

```dart
Future<RobotResponse> turnRight({RobotConfig? config})
```

**Example**:

```dart
await robotApi.turnRight();
```

---

#### Stop()

```dart
Future<RobotResponse> stop({RobotConfig? config})
```

**Example**:

```dart
await robotApi.stop();
```

---

#### enableLineFollow()

```dart
Future<RobotResponse> enableLineFollow({RobotConfig? config})
```

**Example**:

```dart
await robotApi.enableLineFollow();
```

---

### discoverRobot()

Discover robot on network by sending ping.

**Signature**:

```dart
Future<String?> discoverRobot({Duration? timeout})
```

**Parameters**:

- `timeout`: How long to wait for response

**Returns**: IP address if found, `null` otherwise

**Example**:

```dart
final ip = await robotApi.discoverRobot();
if (ip != null) {
  print('Found robot at: $ip');
  robotApi.configure(RobotConfig(ipAddress: ip));
}
```

**Internal Process**:

1. Sends `S` (stop) command via broadcast 3 times
2. Listens for response on UDP port 2001
3. Returns IP of responding device
4. Updates `lastKnownIp` and connection status

---

### Configure()

Update robot configuration.

**Signature**:

```dart
void configure(RobotConfig config)
```

**Example**:

```dart
robotApi.configure(RobotConfig(
  ipAddress: '192.168.43.100',
  resendCount: 5,
));
```

---

### Reset()

Reset connection status.

**Signature**:

```dart
void reset()
```

**Example**:

```dart
robotApi.reset();
// Status back to disconnected
```

---

## Properties

### connectionStatus

Current connection state.

**Type**: `RobotConnectionStatus`

**Example**:

```dart
print(robotApi.connectionStatus);
// Output: RobotConnectionStatus.connected
```

---

### lastKnownIp

Last known IP address of robot.

**Type**: `String?`

**Example**:

```dart
if (robotApi.lastKnownIp != null) {
  print('Robot was last seen at: ${robotApi.lastKnownIp}');
}
```

---

### isConnected

Whether robot is currently connected.

**Type**: `bool`

**Example**:

```dart
if (robotApi.isConnected) {
  await robotApi.moveForward();
} else {
  print('Robot not connected');
}
```

---

## Usage Patterns

### Basic Usage

```dart
import 'package:your_app/services/robot_api.dart';

class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final RobotApi _robotApi = RobotApi();

  Future<void> _moveRobot() async {
    final response = await _robotApi.moveForward();

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Robot moving forward!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${response.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _moveRobot,
      child: Text('Move Forward'),
    );
  }
}
```

---

### With Connection Check

```dart
Future<void> _safeMove() async {
  if (!robotApi.isConnected) {
    // Try to discover robot
    final ip = await robotApi.discoverRobot();
    if (ip == null) {
      throw Exception('Robot not found on network');
    }
  }

  final response = await robotApi.moveForward();
  // Handle response...
}
```

---

### With Custom Config

```dart
final response = await robotApi.moveForward(
  config: RobotConfig(
    ipAddress: '192.168.43.100',  // Direct IP
    resendCount: 5,                // Extra reliability
    timeout: Duration(seconds: 5),
  ),
);
```

---

### With Status Listening

```dart
class RobotStatusWidget extends StatelessWidget {
  final RobotApi robotApi = RobotApi();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: robotApi,
      builder: (context, child) {
        return Text(
          'Status: ${robotApi.connectionStatus}',
          style: TextStyle(
            color: robotApi.isConnected ? Colors.green : Colors.red,
          ),
        );
      },
    );
  }
}
```

---

### Complete Robot Control Page

```dart
class RobotControlPage extends StatefulWidget {
  @override
  _RobotControlPageState createState() => _RobotControlPageState();
}

class _RobotControlPageState extends State<RobotControlPage> {
  final RobotApi _robotApi = RobotApi();
  bool _isLoading = false;

  Future<void> _sendCommand(RobotCommand command) async {
    setState(() => _isLoading = true);

    try {
      final response = await _robotApi.sendCommand(command);

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Command sent: ${command.value}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${response.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Robot Control')),
      body: Column(
        children: [
          // Status
          ListenableBuilder(
            listenable: _robotApi,
            builder: (context, child) => Text(
              'Status: ${_robotApi.connectionStatus}',
            ),
          ),

          // Controls
          if (!_isLoading) ...[
            ElevatedButton(
              onPressed: () => _sendCommand(RobotCommand.forward),
              child: Text('Forward'),
            ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _sendCommand(RobotCommand.left),
                  child: Text('Left'),
                ),
                ElevatedButton(
                  onPressed: () => _sendCommand(RobotCommand.stop),
                  child: Text('Stop'),
                ),
                ElevatedButton(
                  onPressed: () => _sendCommand(RobotCommand.right),
                  child: Text('Right'),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () => _sendCommand(RobotCommand.backward),
              child: Text('Backward'),
            ),
          ] else ...[
            CircularProgressIndicator(),
          ],
        ],
      ),
    );
  }
}
```

---

## Error Handling

### Common Errors

| Error                         | Cause                  | Solution                            |
| ----------------------------- | ---------------------- | ----------------------------------- |
| `Network error: ...`          | Socket creation failed | Check network connectivity          |
| `Failed to send command: ...` | UDP send failed        | Verify IP and port                  |
| Timeout on `discoverRobot()`  | No robot responding    | Check WiFi, verify ESP32 is running |

### Best Practices

```dart
try {
  final response = await robotApi.moveForward();

  if (!response.success) {
    // Command failed but no exception
    logError(response.message);
  }
} on SocketException catch (e) {
  // Network-level error
  showError('Network error: ${e.message}');
} catch (e) {
  // Unexpected error
  showError('Unexpected error: $e');
}
```

---

## Debugging

### Enable Debug Logging

The API includes built-in debug logging:

```dart
// Automatically prints to console:
// - Command being sent
// - Target IP and port
// - Success/failure status
// - Error details
```

### Example Debug Output

```text
Sending command "F" to 255.255.255.255:2001
Command "F" sent successfully (3x redundancy)
```

Or on error:

```text
Socket error sending command: SocketException: Permission denied
```

---

## Related Documentation

- [System Overview](./SYSTEM_OVERVIEW.md) - Architecture
- [Debug Guide](./DEBUG_GUIDE.md) - Testing UDP communication
- [Network Setup](./NETWORK_SETUP.md) - Network configuration

---

Last Updated: 2026-04-07
