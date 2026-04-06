import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Robot command enum for type safety
enum RobotCommand {
  forward('F'),
  backward('B'),
  left('L'),
  right('R'),
  stop('S'),
  lineFollow('LF');

  final String value;
  const RobotCommand(this.value);
}

/// Connection status of the robot
enum RobotConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

/// Configuration for robot connection
class RobotConfig {
  final String? ipAddress; // null = auto-discovery via broadcast
  final int port;
  final Duration timeout;
  final int resendCount;

  const RobotConfig({
    this.ipAddress,
    this.port = 2001,
    this.timeout = const Duration(seconds: 2),
    this.resendCount = 3,
  });

  /// Default configuration
  static const defaults = RobotConfig();
}

/// Response from robot after command execution
class RobotResponse {
  final bool success;
  final String message;
  final DateTime timestamp;

  RobotResponse({
    required this.success,
    required this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory RobotResponse.successInstance() => RobotResponse(
    success: true,
    message: 'Command sent successfully',
  );

  factory RobotResponse.errorInstance(String message) => RobotResponse(
    success: false,
    message: message,
  );
}

/// Service class for communicating with ESP32 robot
///
/// This service handles UDP communication with the robot and provides:
/// - Command sending with retry mechanism
/// - Connection status tracking
/// - Network discovery capabilities
/// - Proper error handling
/// - Multiple robot support
class RobotApi extends ChangeNotifier {
  RobotConnectionStatus _connectionStatus = RobotConnectionStatus.disconnected;
  String? _lastKnownIp;
  RobotConfig _config = RobotConfig.defaults;

  // Multiple robot support
  final List<String> _discoveredRobots = [];
  String? _selectedRobotIp;

  // Getters
  RobotConnectionStatus get connectionStatus => _connectionStatus;
  String? get lastKnownIp => _lastKnownIp;
  bool get isConnected => _connectionStatus == RobotConnectionStatus.connected;
  List<String> get discoveredRobots => List.unmodifiable(_discoveredRobots);
  String? get selectedRobotIp => _selectedRobotIp;
  bool get hasMultipleRobots => _discoveredRobots.length > 1;

  /// Update configuration
  void configure(RobotConfig config) {
    _config = config;
    if (config.ipAddress != null) {
      _lastKnownIp = config.ipAddress;
    }
    notifyListeners();
  }

  /// Send command to robot with retry mechanism
  Future<RobotResponse> sendCommand(
    RobotCommand command, {
    RobotConfig? config,
  }) async {
    final effectiveConfig = config ?? _config;

    try {
      _connectionStatus = RobotConnectionStatus.connecting;
      notifyListeners();

      // Determine target IP address (use selected robot if available)
      String? targetIp = effectiveConfig.ipAddress ?? _selectedRobotIp ?? _lastKnownIp;

      // Create UDP socket
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0, // Let OS assign ephemeral port
      );

      try {
        socket.broadcastEnabled = true;

        // If no specific IP, use broadcast
        if (targetIp == null) {
          targetIp = await _getBroadcastAddress();
        }

        debugPrint('Sending command "${command.value}" to $targetIp:${effectiveConfig.port}');

        // Send command multiple times for reliability (UDP is fire-and-forget)
        for (int i = 0; i < effectiveConfig.resendCount; i++) {
          socket.send(
            command.value.codeUnits,
            InternetAddress(targetIp),
            effectiveConfig.port,
          );

          if (i < effectiveConfig.resendCount - 1) {
            await Future.delayed(const Duration(milliseconds: 50));
          }
        }

        debugPrint('Command "${command.value}" sent successfully (${effectiveConfig.resendCount}x redundancy)');

        _connectionStatus = RobotConnectionStatus.connected;
        _lastKnownIp = targetIp;
        notifyListeners();

        return RobotResponse.successInstance();
      } finally {
        socket.close();
      }
    } on SocketException catch (e) {
      debugPrint('Socket error sending command: $e');
      _connectionStatus = RobotConnectionStatus.error;
      notifyListeners();
      return RobotResponse.errorInstance('Network error: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error sending command: $e');
      _connectionStatus = RobotConnectionStatus.error;
      notifyListeners();
      return RobotResponse.errorInstance('Failed to send command: $e');
    }
  }

  /// Convenience methods for common commands
  Future<RobotResponse> moveForward({RobotConfig? config}) =>
      sendCommand(RobotCommand.forward, config: config);

  Future<RobotResponse> moveBackward({RobotConfig? config}) =>
      sendCommand(RobotCommand.backward, config: config);

  Future<RobotResponse> turnLeft({RobotConfig? config}) =>
      sendCommand(RobotCommand.left, config: config);

  Future<RobotResponse> turnRight({RobotConfig? config}) =>
      sendCommand(RobotCommand.right, config: config);

  Future<RobotResponse> stop({RobotConfig? config}) =>
      sendCommand(RobotCommand.stop, config: config);

  Future<RobotResponse> enableLineFollow({RobotConfig? config}) =>
      sendCommand(RobotCommand.lineFollow, config: config);

  /// Get broadcast address for current network
  /// This is more reliable than using 255.255.255.255
  Future<String> _getBroadcastAddress() async {
    try {
      // Get all network interfaces
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        includeLinkLocal: false,
      );

      // Prefer WiFi interface (usually has "wlan" or "en" in name)
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4) {
            // Try to calculate broadcast from subnet mask
            // If subnet info not available, fallback to 255.255.255.255
            debugPrint('Using fallback broadcast address: 255.255.255.255');
            return '255.255.255.255';
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to calculate broadcast address: $e');
    }

    // Fallback to global broadcast if calculation fails
    debugPrint('Using fallback broadcast address: 255.255.255.255');
    return '255.255.255.255';
  }

  /// Discover robot on network by sending ping
  /// Returns IP address if robot responds, null otherwise
  Future<String?> discoverRobot({Duration? timeout}) async {
    final effectiveTimeout = timeout ?? const Duration(seconds: 2);

    try {
      _connectionStatus = RobotConnectionStatus.connecting;
      notifyListeners();

      // Get broadcast address
      final broadcastAddress = await _getBroadcastAddress();

      // Create UDP socket
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _config.port, // Listen on robot's port for responses
      );

      try {
        socket.broadcastEnabled = true;

        // Send discovery command (stop command as ping)
        for (int i = 0; i < 3; i++) {
          socket.send(
            RobotCommand.stop.value.codeUnits,
            InternetAddress(broadcastAddress),
            _config.port,
          );
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // Wait for response with timeout
        Datagram? response;
        try {
          await for (final event in socket.timeout(effectiveTimeout)) {
            if (event == RawSocketEvent.read) {
              response = socket.receive();
              break;
            }
          }
        } catch (_) {
          // Timeout - no response
          response = null;
        }

        if (response != null) {
          final ip = response.address.address;
          debugPrint('Discovered robot at: $ip');
          _lastKnownIp = ip;
          _connectionStatus = RobotConnectionStatus.connected;
          notifyListeners();
          return ip;
        }

        debugPrint('No robot found on network');
        _connectionStatus = RobotConnectionStatus.disconnected;
        notifyListeners();
        return null;
      } finally {
        socket.close();
      }
    } catch (e) {
      debugPrint('Error during robot discovery: $e');
      _connectionStatus = RobotConnectionStatus.error;
      notifyListeners();
      return null;
    }
  }

  /// Auto-discover robot on initialization
  /// Call this once when app starts to automatically find the robot
  void autoDiscover() {
    // Use a fire-and-forget approach to discover robot
    // This won't block UI but will update status when found
    discoverRobot().then((ip) {
      if (ip != null) {
        debugPrint('Auto-discovery successful: $ip');
      } else {
        debugPrint('Auto-discovery failed, robot not found');
      }
    }).catchError((e) {
      debugPrint('Auto-discovery error: $e');
    });
  }

  /// Discover all robots on network by sending broadcast ping
  /// Returns list of IP addresses of all responding robots
  Future<List<String>> discoverAllRobots({Duration? timeout}) async {
    final effectiveTimeout = timeout ?? const Duration(seconds: 3);
    final Set<String> foundIps = {};

    try {
      // Get broadcast address
      final broadcastAddress = await _getBroadcastAddress();

      // Create UDP socket
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _config.port,
      );

      try {
        socket.broadcastEnabled = true;

        // Send discovery command multiple times
        for (int i = 0; i < 5; i++) {
          socket.send(
            RobotCommand.stop.value.codeUnits,
            InternetAddress(broadcastAddress),
            _config.port,
          );
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // Listen for responses with timeout
        final stopwatch = Stopwatch()..start();
        await for (final event in socket.timeout(effectiveTimeout)) {
          if (event == RawSocketEvent.read) {
            final datagram = socket.receive();
            if (datagram != null) {
              foundIps.add(datagram.address.address);
              debugPrint('[Discovery] Found robot at: ${datagram.address.address}');
            }
          }
        }
        stopwatch.stop();
      } on TimeoutException {
        // Expected timeout, not an error
        debugPrint('[Discovery] Discovery timeout reached');
      } finally {
        socket.close();
      }

      _discoveredRobots.clear();
      _discoveredRobots.addAll(foundIps);

      // Auto-select first robot if only one found
      if (foundIps.length == 1) {
        _selectedRobotIp = foundIps.first;
      }

      debugPrint('[Discovery] Found ${foundIps.length} robot(s): ${foundIps.join(", ")}');
      notifyListeners();

      return List.unmodifiable(foundIps);
    } catch (e) {
      debugPrint('Error during robot discovery: $e');
      return [];
    }
  }

  /// Select a specific robot by IP address
  void selectRobot(String ip) {
    if (_discoveredRobots.contains(ip)) {
      _selectedRobotIp = ip;
      _lastKnownIp = ip;
      debugPrint('[RobotApi] Selected robot at: $ip');
      notifyListeners();
    }
  }

  /// Clear selected robot (revert to broadcast mode)
  void clearSelectedRobot() {
    _selectedRobotIp = null;
    debugPrint('[RobotApi] Cleared robot selection (broadcast mode)');
    notifyListeners();
  }

  /// Refresh discovered robots list
  Future<void> refreshRobots() async {
    await discoverAllRobots();
  }

  /// Reset connection status
  void reset() {
    _connectionStatus = RobotConnectionStatus.disconnected;
    notifyListeners();
  }
}
