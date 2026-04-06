import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/robot_api.dart';
import '../theme/app_theme.dart';

/// Manual control page for ESP32 robot
/// Provides directional buttons, speed control, and line follow mode
class RobotControlPage extends StatefulWidget {
  const RobotControlPage({super.key});

  @override
  State<RobotControlPage> createState() => _RobotControlPageState();
}

class _RobotControlPageState extends State<RobotControlPage> {
  bool _isLineFollowing = false;
  final Set<String> _pressedButtons = {};

  void _sendCommand(RobotCommand command) {
    final robotApi = context.read<RobotApi>();

    if (!robotApi.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('หุ่นยนต์ยังไม่เชื่อมต่อ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    debugPrint('[RobotControl] Sending command: ${command.value}');

    robotApi.sendCommand(command).then((response) {
      if (!mounted) return;

      if (response.success) {
        debugPrint('[RobotControl] Command sent successfully: ${command.value}');
        if (command == RobotCommand.lineFollow) {
          setState(() => _isLineFollowing = true);
        } else if (command == RobotCommand.stop) {
          setState(() => _isLineFollowing = false);
        }
      } else {
        debugPrint('[RobotControl] Command failed: ${response.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    }).catchError((error) {
      if (!mounted) return;
      debugPrint('[RobotControl] Error sending command: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _onButtonPressed(String buttonId, RobotCommand command) {
    setState(() => _pressedButtons.add(buttonId));
    _sendCommand(command);

    // Haptic feedback
    HapticFeedback.mediumImpact();
  }

  void _onButtonReleased(String buttonId) {
    setState(() => _pressedButtons.remove(buttonId));
  }

  Future<void> _refreshRobots() async {
    final robotApi = context.read<RobotApi>();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('กำลังค้นหาหุ่นยนต์...'),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.blue,
      ),
    );

    final robots = await robotApi.discoverAllRobots();

    if (!mounted) return;

    if (robots.isNotEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('พบหุ่นยนต์ ${robots.length} ตัว'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {}); // Refresh UI
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่พบหุ่นยนต์บนเครือข่าย'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ควบคุมหุ่นยนต์'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshRobots,
            tooltip: 'ค้นหาหุ่นยนต์ใหม่',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryGreen.withOpacity(0.1), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Connection Status Header
              _buildConnectionStatus(),

              const SizedBox(height: 16),

              // Robot Selector Dropdown
              _buildRobotSelector(),

              const SizedBox(height: 24),

              // Mode Toggle
              _buildModeToggle(),

              const SizedBox(height: 32),

              // D-Pad Control
              Expanded(
                child: _buildDPad(),
              ),

              const SizedBox(height: 24),

              // Stop Button (Emergency)
              _buildEmergencyStop(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return ListenableBuilder(
      listenable: context.read<RobotApi>(),
      builder: (context, child) {
        final robotApi = context.read<RobotApi>();
        final status = robotApi.connectionStatus;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: _getStatusColor(status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getStatusColor(status),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getStatusColor(status).withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _getStatusText(status),
                style: TextStyle(
                  color: _getStatusColor(status),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (robotApi.selectedRobotIp != null) ...[
                const SizedBox(width: 12),
                Text(
                  robotApi.selectedRobotIp!,
                  style: TextStyle(
                    color: _getStatusColor(status).withOpacity(0.6),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildRobotSelector() {
    return ListenableBuilder(
      listenable: context.read<RobotApi>(),
      builder: (context, child) {
        final robotApi = context.read<RobotApi>();
        final robots = robotApi.discoveredRobots;
        final selectedIp = robotApi.selectedRobotIp;

        // If no robots discovered, show broadcast mode
        if (robots.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.wifi_tethering, color: Colors.grey, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'โหมดกระจายสัญญาณ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'ส่งคำสั่งไปทุกหุ่นยนต์',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _refreshRobots,
                  child: const Text('ค้นหา'),
                ),
              ],
            ),
          );
        }

        // Show dropdown for multiple robots
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.smart_toy, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedIp,
                    hint: const Text('เลือกหุ่นยนต์'),
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    items: [
                      // Broadcast option
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text(
                          'ทั้งหมด (กระจายสัญญาณ)',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      // Individual robots
                      ...robots.map((ip) {
                        return DropdownMenuItem<String>(
                          value: ip,
                          child: Text(
                            ip,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                    onChanged: (ip) {
                      if (ip != null) {
                        robotApi.selectRobot(ip);
                      } else {
                        robotApi.clearSelectedRobot();
                      }
                    },
                  ),
                ),
              ),
              if (selectedIp != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () => robotApi.clearSelectedRobot(),
                  tooltip: 'ยกเลิกการเลือก',
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              label: 'ควบคุมเอง',
              isSelected: !_isLineFollowing,
              onTap: () {
                setState(() => _isLineFollowing = false);
                _sendCommand(RobotCommand.stop);
              },
            ),
          ),
          Expanded(
            child: _ModeButton(
              label: 'ตามเส้น',
              isSelected: _isLineFollowing,
              onTap: () {
                setState(() => _isLineFollowing = true);
                _sendCommand(RobotCommand.lineFollow);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDPad() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Make D-Pad responsive based on available width
        final maxWidth = constraints.maxWidth;
        final buttonSize = (maxWidth * 0.28).clamp(60.0, 80.0);
        final centerSize = (maxWidth * 0.28).clamp(60.0, 80.0);
        final spacing = (maxWidth * 0.03).clamp(6.0, 8.0);

        return SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Forward button
              _buildDirectionButton(
                'forward',
                RobotCommand.forward,
                Icons.keyboard_arrow_up,
                Alignment.topCenter,
                buttonSize: buttonSize,
              ),

              SizedBox(height: spacing),

              // Middle row: Left, Center (Stop), Right
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Left button
                  _buildDirectionButton(
                    'left',
                    RobotCommand.left,
                    Icons.keyboard_arrow_left,
                    Alignment.centerLeft,
                    buttonSize: buttonSize,
                  ),

                  SizedBox(width: spacing),

                  // Center indicator
                  Container(
                    width: centerSize,
                    height: centerSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade200,
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _isLineFollowing ? 'ตาม\nเส้น' : 'หยุด',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _isLineFollowing ? AppTheme.primaryGreen : Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: spacing),

                  // Right button
                  _buildDirectionButton(
                    'right',
                    RobotCommand.right,
                    Icons.keyboard_arrow_right,
                    Alignment.centerRight,
                    buttonSize: buttonSize,
                  ),
                ],
              ),

              SizedBox(height: spacing),

              // Backward button
              _buildDirectionButton(
                'backward',
                RobotCommand.backward,
                Icons.keyboard_arrow_down,
                Alignment.bottomCenter,
                buttonSize: buttonSize,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDirectionButton(
    String buttonId,
    RobotCommand command,
    IconData icon,
    Alignment alignment, {
    double? buttonSize,
  }) {
    final isPressed = _pressedButtons.contains(buttonId);
    final size = buttonSize ?? 80;

    return GestureDetector(
      onTapDown: (_) => _onButtonPressed(buttonId, command),
      onTapUp: (_) => _onButtonReleased(buttonId),
      onTapCancel: () => _onButtonReleased(buttonId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isPressed ? AppTheme.primaryGreen.withOpacity(0.3) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isPressed ? AppTheme.primaryGreen : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: isPressed
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Icon(
          icon,
          size: size * 0.6,
          color: isPressed ? AppTheme.primaryGreen : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildEmergencyStop() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton.icon(
          onPressed: () {
            _onButtonPressed('stop', RobotCommand.stop);
            HapticFeedback.heavyImpact();
          },
          icon: const Icon(Icons.stop_circle, size: 28),
          label: const Text(
            'หยุดฉุกเฉิน',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(RobotConnectionStatus status) {
    switch (status) {
      case RobotConnectionStatus.connected:
        return Colors.green;
      case RobotConnectionStatus.connecting:
        return Colors.orange;
      case RobotConnectionStatus.error:
        return Colors.red;
      case RobotConnectionStatus.disconnected:
        return Colors.grey;
    }
  }

  String _getStatusText(RobotConnectionStatus status) {
    switch (status) {
      case RobotConnectionStatus.connected:
        return 'หุ่นยนต์พร้อมใช้งาน';
      case RobotConnectionStatus.connecting:
        return 'กำลังเชื่อมต่อ...';
      case RobotConnectionStatus.error:
        return 'เกิดข้อผิดพลาด';
      case RobotConnectionStatus.disconnected:
        return 'ยังไม่เชื่อมต่อ';
    }
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
