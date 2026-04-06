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

    robotApi.sendCommand(command).then((response) {
      if (!mounted) return;

      if (response.success) {
        if (command == RobotCommand.lineFollow) {
          setState(() => _isLineFollowing = true);
        } else if (command == RobotCommand.stop) {
          setState(() => _isLineFollowing = false);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ควบคุมหุ่นยนต์'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
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
              if (robotApi.lastKnownIp != null) ...[
                const SizedBox(width: 12),
                Text(
                  robotApi.lastKnownIp!,
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
    return SizedBox(
      width: 280,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Forward button
          _buildDirectionButton(
            'forward',
            RobotCommand.forward,
            Icons.keyboard_arrow_up,
            Alignment.topCenter,
          ),

          const SizedBox(height: 8),

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
              ),

              const SizedBox(width: 8),

              // Center indicator
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: Center(
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

              const SizedBox(width: 8),

              // Right button
              _buildDirectionButton(
                'right',
                RobotCommand.right,
                Icons.keyboard_arrow_right,
                Alignment.centerRight,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Backward button
          _buildDirectionButton(
            'backward',
            RobotCommand.backward,
            Icons.keyboard_arrow_down,
            Alignment.bottomCenter,
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionButton(
    String buttonId,
    RobotCommand command,
    IconData icon,
    Alignment alignment,
  ) {
    final isPressed = _pressedButtons.contains(buttonId);

    return GestureDetector(
      onTapDown: (_) => _onButtonPressed(buttonId, command),
      onTapUp: (_) => _onButtonReleased(buttonId),
      onTapCancel: () => _onButtonReleased(buttonId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 80,
        height: 80,
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
          size: 48,
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
