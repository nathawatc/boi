import 'package:flutter/material.dart';
import '../services/robot_api.dart';

/// Widget that displays the current robot connection status
/// Shows a colored indicator with status text and allows manual refresh
class RobotStatusIndicator extends StatelessWidget {
  final RobotApi robotApi;
  final bool showRefreshButton;
  final bool showTapToDiscover;
  final bool showIp;

  const RobotStatusIndicator({
    super.key,
    required this.robotApi,
    this.showRefreshButton = true,
    this.showTapToDiscover = true,
    this.showIp = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: robotApi,
      builder: (context, child) {
        // Build display text - status only, or status + IP
        String displayText = _getStatusText(robotApi.connectionStatus);
        if (showIp && robotApi.lastKnownIp != null && robotApi.isConnected) {
          displayText = '$displayText ${robotApi.lastKnownIp}';
        }

        return GestureDetector(
          onTap: showTapToDiscover && !robotApi.isConnected
              ? () => _discoverRobot(context)
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _getStatusColor(robotApi.connectionStatus).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getStatusColor(robotApi.connectionStatus),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status dot
                _buildStatusDot(context),
                const SizedBox(width: 8),
                // Combined text - status + IP in one Text widget
                Flexible(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      color: _getStatusColor(robotApi.connectionStatus),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showRefreshButton && robotApi.connectionStatus == RobotConnectionStatus.disconnected) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.refresh,
                    size: 16,
                    color: _getStatusColor(robotApi.connectionStatus),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusDot(BuildContext context) {
    final status = robotApi.connectionStatus;
    final color = _getStatusColor(status);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
      ),
      child: status == RobotConnectionStatus.connecting
          ? const SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : null,
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
        return 'พร้อมใช้งาน';
      case RobotConnectionStatus.connecting:
        return 'กำลังเชื่อมต่อ';
      case RobotConnectionStatus.error:
        return 'ผิดพลาด';
      case RobotConnectionStatus.disconnected:
        return 'ไม่เชื่อมต่อ';
    }
  }

  Future<void> _discoverRobot(BuildContext context) async {
    final scaffold = ScaffoldMessenger.of(context);

    // Show loading
    scaffold.showSnackBar(
      SnackBar(
        content: Text('กำลังค้นหาหุ่นยนต์บนเครือข่าย...'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blue,
      ),
    );

    try {
      final ip = await robotApi.discoverRobot();

      if (!context.mounted) return;

      if (ip != null) {
        scaffold.hideCurrentSnackBar();
        scaffold.showSnackBar(
          SnackBar(
            content: Text('พบหุ่นยนต์ที่: $ip'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'ตกลง',
              textColor: Colors.white,
              onPressed: () => scaffold.hideCurrentSnackBar(),
            ),
          ),
        );
      } else {
        scaffold.hideCurrentSnackBar();
        scaffold.showSnackBar(
          SnackBar(
            content: Text('ไม่พบหุ่นยนต์บนเครือข่าย'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'ตกลง',
              textColor: Colors.white,
              onPressed: () => scaffold.hideCurrentSnackBar(),
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      scaffold.hideCurrentSnackBar();
      scaffold.showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
