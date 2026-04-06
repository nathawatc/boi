import 'package:flutter_test/flutter_test.dart';
import 'package:customer/services/robot_api.dart';

void main() {
  group('RobotCommand', () {
    test('all commands have correct values', () {
      expect(RobotCommand.forward.value, 'F');
      expect(RobotCommand.backward.value, 'B');
      expect(RobotCommand.left.value, 'L');
      expect(RobotCommand.right.value, 'R');
      expect(RobotCommand.stop.value, 'S');
      expect(RobotCommand.lineFollow.value, 'LF');
    });
  });

  group('RobotConnectionStatus', () {
    test('has all expected states', () {
      expect(RobotConnectionStatus.values.length, 4);
      expect(RobotConnectionStatus.disconnected.index, 0);
      expect(RobotConnectionStatus.connecting.index, 1);
      expect(RobotConnectionStatus.connected.index, 2);
      expect(RobotConnectionStatus.error.index, 3);
    });
  });

  group('RobotConfig', () {
    test('default config has correct values', () {
      const config = RobotConfig.defaults;
      expect(config.ipAddress, isNull);
      expect(config.port, 2001);
      expect(config.timeout, const Duration(seconds: 2));
      expect(config.resendCount, 3);
    });

    test('custom config can be created', () {
      const config = RobotConfig(
        ipAddress: '192.168.43.1',
        port: 3000,
        timeout: Duration(seconds: 5),
        resendCount: 5,
      );
      expect(config.ipAddress, '192.168.43.1');
      expect(config.port, 3000);
      expect(config.resendCount, 5);
    });
  });

  group('RobotResponse', () {
    test('success instance has correct values', () {
      final response = RobotResponse.successInstance();
      expect(response.success, true);
      expect(response.message, 'Command sent successfully');
      expect(response.timestamp, isNotNull);
    });

    test('error instance has correct values', () {
      final response = RobotResponse.errorInstance('Test error');
      expect(response.success, false);
      expect(response.message, 'Test error');
    });
  });

  group('isValidIPv4', () {
    test('valid IPv4 addresses return true', () {
      expect(isValidIPv4('192.168.43.1'), true);
      expect(isValidIPv4('10.0.0.1'), true);
      expect(isValidIPv4('255.255.255.255'), true);
      expect(isValidIPv4('0.0.0.0'), true);
    });

    test('invalid IPv4 addresses return false', () {
      expect(isValidIPv4(''), false);
      expect(isValidIPv4('not-an-ip'), false);
      expect(isValidIPv4('256.256.256.256'), false);
      expect(isValidIPv4('192.168.1'), false);
    });
  });

  group('calculateBroadcastAddress', () {
    test('calculates correct broadcast for /24 subnet', () {
      expect(
        calculateBroadcastAddress('192.168.43.100', prefixLength: 24),
        '192.168.43.255',
      );
    });

    test('handles /16 subnet', () {
      expect(
        calculateBroadcastAddress('10.0.50.100', prefixLength: 16),
        '10.0.255.255',
      );
    });

    test('returns fallback for invalid IP', () {
      expect(
        calculateBroadcastAddress('invalid', prefixLength: 24),
        '255.255.255.255',
      );
    });
  });

  group('RobotApi', () {
    late RobotApi api;

    setUp(() {
      api = RobotApi();
    });

    tearDown(() {
      api.dispose();
    });

    test('starts disconnected', () {
      expect(api.connectionStatus, RobotConnectionStatus.disconnected);
      expect(api.isConnected, false);
    });

    test('discoveredRobots returns empty list initially', () {
      expect(api.discoveredRobots, isEmpty);
    });

    test('hasMultipleRobots is false initially', () {
      expect(api.hasMultipleRobots, false);
    });

    test('isManualIpConfigured is false initially', () {
      expect(api.isManualIpConfigured, false);
    });

    test('effectiveTargetIp is null initially', () {
      expect(api.effectiveTargetIp, isNull);
    });

    test('setManualIp returns true for valid IP', () {
      expect(api.setManualIp('192.168.43.1'), true);
      expect(api.isManualIpConfigured, true);
      expect(api.effectiveTargetIp, '192.168.43.1');
    });

    test('setManualIp returns false for invalid IP', () {
      expect(api.setManualIp('not-an-ip'), false);
      expect(api.isManualIpConfigured, false);
    });

    test('selectRobot returns true for valid IP', () {
      expect(api.selectRobot('192.168.43.1'), true);
      expect(api.selectedRobotIp, '192.168.43.1');
      expect(api.isManualIpConfigured, true);
    });

    test('selectRobot returns false for invalid IP', () {
      expect(api.selectRobot('invalid'), false);
    });

    test('clearManualIp resets flag', () {
      api.setManualIp('192.168.43.1');
      api.clearManualIp();
      expect(api.isManualIpConfigured, false);
    });

    test('clearSelectedRobot clears selection', () {
      api.selectRobot('192.168.43.1');
      api.clearSelectedRobot();
      expect(api.selectedRobotIp, isNull);
    });

    test('reset sets status to disconnected', () {
      api.reset();
      expect(api.connectionStatus, RobotConnectionStatus.disconnected);
    });

    test('configure updates config', () {
      api.configure(const RobotConfig(ipAddress: '10.0.0.1'));
      expect(api.isManualIpConfigured, true);
    });
  });
}
