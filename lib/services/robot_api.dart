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
    this.timeout = const Duration(seconds: 5),
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

/// Validate an IPv4 address string
/// Returns true if the string is a valid IPv4 address
bool isValidIPv4(String ip) {
  try {
    final address = InternetAddress(ip);
    return address.type == InternetAddressType.IPv4;
  } catch (_) {
    return false;
  }
}

/// Calculate broadcast address from an IP address and subnet prefix length
/// Falls back to global broadcast (255.255.255.255) if calculation fails
String calculateBroadcastAddress(String ip, {int prefixLength = 24}) {
  try {
    final ipBytes = InternetAddress(ip).rawAddress;
    if (ipBytes.length != 4) return '255.255.255.255';

    // Calculate subnet mask from prefix length
    final mask = prefixLength == 0
        ? 0x00000000
        : (0xFFFFFFFF << (32 - prefixLength)) & 0xFFFFFFFF;

    // Calculate broadcast: (ip & mask) | (~mask & 0xFFFFFFFF)
    final ipInt = (ipBytes[0] << 24) | (ipBytes[1] << 16) | (ipBytes[2] << 8) | ipBytes[3];
    final network = ipInt & mask;
    final broadcast = network | (~mask & 0xFFFFFFFF);

    return '${(broadcast >> 24) & 0xFF}.${(broadcast >> 16) & 0xFF}.${(broadcast >> 8) & 0xFF}.${broadcast & 0xFF}';
  } catch (e) {
    debugPrint('Failed to calculate broadcast address: $e');
    return '255.255.255.255';
  }
}

/// Service class for communicating with ESP32 robot
///
/// This service handles UDP communication with the robot and provides:
/// - Command sending with retry mechanism
/// - Connection status tracking
/// - Network discovery capabilities
/// - Proper error handling
/// - Multiple robot support
/// - Manual IP configuration
class RobotApi extends ChangeNotifier {
  RobotConnectionStatus _connectionStatus = RobotConnectionStatus.disconnected;
  String? _lastKnownIp;
  RobotConfig _config = RobotConfig.defaults;

  // Multiple robot support
  final List<String> _discoveredRobots = [];
  String? _selectedRobotIp;
  bool _isManualIpConfigured = false;

  RawDatagramSocket? _socket;
  bool _isInitialized = false;

  // Getters
  RobotConnectionStatus get connectionStatus => _connectionStatus;
  String? get lastKnownIp => _lastKnownIp;
  bool get isConnected => _connectionStatus == RobotConnectionStatus.connected;
  List<String> get discoveredRobots => List.unmodifiable(_discoveredRobots);
  String? get selectedRobotIp => _selectedRobotIp;
  bool get hasMultipleRobots => _discoveredRobots.length > 1;
  bool get isManualIpConfigured => _isManualIpConfigured;

  /// Initialize the API and create the reusable socket
  /// Must be called before using sendCommand or other methods
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0, // Let OS assign ephemeral port
      );
      _socket!.broadcastEnabled = true;
      _isInitialized = true;
      debugPrint('[RobotApi] Socket initialized and ready');
    } catch (e) {
      debugPrint('[RobotApi] Failed to initialize socket: $e');
      _isInitialized = false;
    }
  }

  @override
  void dispose() {
    _socket?.close();
    _socket = null;
    _isInitialized = false;
    debugPrint('[RobotApi] Socket closed');
    super.dispose();
  }

  /// Get the effective target IP (manual > selected > last known > null for broadcast)
  String? get effectiveTargetIp {
    if (_selectedRobotIp != null) return _selectedRobotIp;
    if (_lastKnownIp != null) return _lastKnownIp;
    return null;
  }

  /// Update configuration
  void configure(RobotConfig config) {
    _config = config;
    if (config.ipAddress != null && isValidIPv4(config.ipAddress!)) {
      _lastKnownIp = config.ipAddress;
      _isManualIpConfigured = true;
    }
    notifyListeners();
  }

  /// Set manual IP address for robot connection
  /// Returns true if IP is valid, false otherwise
  bool setManualIp(String ip) {
    if (!isValidIPv4(ip)) {
      debugPrint('[RobotApi] Invalid IP address: $ip');
      return false;
    }
    _selectedRobotIp = ip;
    _lastKnownIp = ip;
    _isManualIpConfigured = true;
    debugPrint('[RobotApi] Manual IP set: $ip');
    notifyListeners();
    return true;
  }

  /// Clear manual IP configuration (revert to auto-discovery mode)
  void clearManualIp() {
    _isManualIpConfigured = false;
    // Don't clear _selectedRobotIp if robots were discovered
    if (_discoveredRobots.isEmpty) {
      _selectedRobotIp = null;
      _lastKnownIp = null;
    }
    debugPrint('[RobotApi] Cleared manual IP configuration');
    notifyListeners();
  }

  /// Send command to robot with retry mechanism
  Future<RobotResponse> sendCommand(
    RobotCommand command, {
    RobotConfig? config,
  }) async {
    // Check if socket is initialized
    if (!_isInitialized || _socket == null) {
      debugPrint('[RobotApi] ERROR: Socket not initialized. Call initialize() first.');
      return RobotResponse.errorInstance('RobotApi not initialized');
    }

    final effectiveConfig = config ?? _config;

    try {
      _connectionStatus = RobotConnectionStatus.connecting;
      notifyListeners();

      // Determine target IP address (use selected robot if available)
      String? targetIp = effectiveConfig.ipAddress ?? _selectedRobotIp ?? _lastKnownIp;

      // If no specific IP, use broadcast
      if (targetIp == null) {
        targetIp = await _getBroadcastAddress();
      } else {
        _lastKnownIp ??= targetIp;
      }

      debugPrint('Sending command "${command.value}" to $targetIp:${effectiveConfig.port}');

      // Send command multiple times for reliability (UDP is fire-and-forget)
      for (int i = 0; i < effectiveConfig.resendCount; i++) {
        _socket!.send(
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
      if (targetIp != '255.255.255.255') {
        _lastKnownIp = targetIp;
      }
      notifyListeners();

      return RobotResponse.successInstance();
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
  /// Attempts to calculate subnet-specific broadcast from network interfaces
  /// Falls back to global broadcast (255.255.255.255) if calculation fails
  Future<String> _getBroadcastAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        includeLinkLocal: false,
      );

      // Prefer WiFi interfaces (wlan, en, wl) over others
      for (final interface in interfaces) {
        final name = interface.name.toLowerCase();
        if (name.contains('wlan') || name.contains('wl') || name.contains('en')) {
          for (final address in interface.addresses) {
            if (address.type == InternetAddressType.IPv4) {
              // Use /24 as default subnet (common for mobile hotspots)
              final broadcast = calculateBroadcastAddress(address.address, prefixLength: 24);
              debugPrint('Calculated broadcast address: $broadcast (from ${address.address} on ${interface.name})');
              return broadcast;
            }
          }
        }
      }

      // Fallback: use any IPv4 interface
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4) {
            final broadcast = calculateBroadcastAddress(address.address, prefixLength: 24);
            debugPrint('Calculated broadcast address: $broadcast (from ${address.address})');
            return broadcast;
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to calculate broadcast address: $e');
    }

    // Final fallback to global broadcast
    debugPrint('Using fallback broadcast address: 255.255.255.255');
    return '255.255.255.255';
  }

  /// Discover robot on network by sending ping
  /// Returns IP address if robot responds, null otherwise
  Future<String?> discoverRobot({Duration? timeout}) async {
    final effectiveTimeout = timeout ?? const Duration(seconds: 5);

    try {
      _connectionStatus = RobotConnectionStatus.connecting;
      notifyListeners();

      // Get broadcast address
      final broadcastAddress = await _getBroadcastAddress();

      // Create UDP socket with ephemeral port (not robot port)
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0, // Let OS assign ephemeral port for discovery
      );

      try {
        socket.broadcastEnabled = true;

        // Start listening BEFORE sending discovery packet
        // This ensures we don't miss the response
        Datagram? response;
        final completer = Completer<void>();
        final subscription = socket.listen(
          (event) {
            if (!completer.isCompleted) {
              final datagram = socket.receive();
              if (datagram != null) {
                response = datagram;
                completer.complete();
              }
            }
          },
          onError: (_) {
            if (!completer.isCompleted) completer.complete();
          },
        );

        // Send discovery command (stop command as ping) - 3x for redundancy
        for (int i = 0; i < 3; i++) {
          socket.send(
            RobotCommand.stop.value.codeUnits,
            InternetAddress(broadcastAddress),
            _config.port,
          );
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // Wait for response with timeout
        try {
          await completer.future.timeout(effectiveTimeout);
        } on TimeoutException {
          // Expected timeout - robot not found
          debugPrint('[Discovery] No robot responded within timeout');
        }

        await subscription.cancel();

        if (response != null) {
          final ip = response!.address.address;
          debugPrint('Discovered robot at: $ip');
          _lastKnownIp = ip;
          _selectedRobotIp = ip;
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
    } on SocketException catch (e) {
      debugPrint('Socket error during discovery: $e');
      _connectionStatus = RobotConnectionStatus.disconnected;
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Error during robot discovery: $e');
      _connectionStatus = RobotConnectionStatus.disconnected;
      notifyListeners();
      return null;
    }
  }

  /// Auto-discover robot on initialization
  /// Call this once when app starts to automatically find the robot
  void autoDiscover() {
    discoverRobot().then((ip) {
      if (ip != null) {
        debugPrint('[RobotApi] Auto-discovery successful: $ip');
        // _selectedRobotIp is already set in discoverRobot()
      } else {
        debugPrint('[RobotApi] Auto-discovery failed, robot not found');
        _connectionStatus = RobotConnectionStatus.disconnected;
        notifyListeners();
      }
    }).catchError((e) {
      debugPrint('[RobotApi] Auto-discovery error: $e');
      _connectionStatus = RobotConnectionStatus.disconnected;
      notifyListeners();
    });
  }

  /// Discover all robots on network by sending broadcast ping
  /// Returns list of IP addresses of all responding robots
  Future<List<String>> discoverAllRobots({Duration? timeout}) async {
    final effectiveTimeout = timeout ?? const Duration(seconds: 6);
    final Set<String> foundIps = {};

    try {
      // Get broadcast address
      final broadcastAddress = await _getBroadcastAddress();

      // Create UDP socket with ephemeral port
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0, // Let OS assign ephemeral port
      );

      try {
        socket.broadcastEnabled = true;

        // Start listening BEFORE sending discovery packets
        final stopwatch = Stopwatch()..start();
        final completer = Completer<void>();
        final subscription = socket.listen(
          (event) {
            final datagram = socket.receive();
            if (datagram != null) {
              foundIps.add(datagram.address.address);
              debugPrint('[Discovery] Found robot at: ${datagram.address.address}');
              // Complete after finding at least one robot and a short grace period
              if (foundIps.length == 1 && !completer.isCompleted) {
                // Wait 500ms to collect any additional robots
                Timer(const Duration(milliseconds: 500), () {
                  if (!completer.isCompleted) completer.complete();
                });
              }
            }
          },
          onError: (_) {
            if (!completer.isCompleted) completer.complete();
          },
        );

        // Send discovery command multiple times for redundancy
        for (int i = 0; i < 5; i++) {
          socket.send(
            RobotCommand.stop.value.codeUnits,
            InternetAddress(broadcastAddress),
            _config.port,
          );
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // Wait for all responses with timeout
        try {
          await completer.future.timeout(effectiveTimeout);
        } on TimeoutException {
          debugPrint('[Discovery] Discovery timeout reached (${stopwatch.elapsedMilliseconds}ms)');
        }

        await subscription.cancel();
        stopwatch.stop();
      } finally {
        socket.close();
      }

      _discoveredRobots.clear();
      _discoveredRobots.addAll(foundIps);

      // Auto-select first robot if only one found and no manual IP configured
      if (foundIps.length == 1 && !_isManualIpConfigured) {
        _selectedRobotIp = foundIps.first;
      }

      debugPrint('[Discovery] Found ${foundIps.length} robot(s): ${foundIps.join(", ")}');
      _connectionStatus = foundIps.isNotEmpty
          ? RobotConnectionStatus.connected
          : RobotConnectionStatus.disconnected;
      notifyListeners();

      return List.unmodifiable(foundIps);
    } catch (e) {
      debugPrint('Error during robot discovery: $e');
      _connectionStatus = RobotConnectionStatus.disconnected;
      notifyListeners();
      return [];
    }
  }

  /// Select a specific robot by IP address
  /// Accepts any valid IPv4 address, not just discovered robots
  bool selectRobot(String ip) {
    if (!isValidIPv4(ip)) {
      debugPrint('[RobotApi] Cannot select invalid IP: $ip');
      return false;
    }
    _selectedRobotIp = ip;
    _lastKnownIp = ip;
    _isManualIpConfigured = !_discoveredRobots.contains(ip);
    debugPrint('[RobotApi] Selected robot at: $ip (manual: $_isManualIpConfigured)');
    notifyListeners();
    return true;
  }

  /// Clear selected robot (revert to broadcast mode)
  void clearSelectedRobot() {
    _selectedRobotIp = null;
    _isManualIpConfigured = false;
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
