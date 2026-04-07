import 'package:flutter/material.dart';
import '../services/robot_api.dart';

/// Widget that displays the current robot connection status
/// Shows a colored indicator with status text and allows manual refresh
class RobotStatusIndicator extends StatelessWidget {
  final RobotApi robotApi;
  final bool showRefreshButton;
  final bool showTapToDiscover;
  final bool showIp;
  final VoidCallback? onSettingsTap;

  const RobotStatusIndicator({
    super.key,
    required this.robotApi,
    this.showRefreshButton = true,
    this.showTapToDiscover = true,
    this.showIp = true,
    this.onSettingsTap,
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
          onLongPress: onSettingsTap ?? () => _showManualIpDialog(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _getStatusColor(robotApi.connectionStatus).withValues(alpha: 0.1),
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
            color: color.withValues(alpha: 0.5),
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

  /// Show dialog for manual IP entry
  void _showManualIpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => _ManualIpInputDialog(
        robotApi: robotApi,
      ),
    );
  }
}

/// Dialog for entering manual IP address
class _ManualIpInputDialog extends StatefulWidget {
  final RobotApi robotApi;

  const _ManualIpInputDialog({required this.robotApi});

  @override
  State<_ManualIpInputDialog> createState() => _ManualIpInputDialogState();
}

class _ManualIpInputDialogState extends State<_ManualIpInputDialog> {
  final _ipController = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with last known IP or selected IP
    _ipController.text = widget.robotApi.effectiveTargetIp ?? '192.168.43.1';
    _validateIp(_ipController.text);
    _ipController.addListener(() => _validateIp(_ipController.text));
  }

  void _validateIp(String value) {
    setState(() {
      _isValid = isValidIPv4(value.trim());
    });
  }

  void _connect() {
    final ip = _ipController.text.trim();
    if (isValidIPv4(ip)) {
      widget.robotApi.selectRobot(ip);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เชื่อมต่อหุ่นยนต์ที่: $ip'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ระบุ IP หุ่นยนต์'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _ipController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'เช่น 192.168.43.1',
              labelText: 'IP Address',
              border: const OutlineInputBorder(),
              errorText: _isValid ? null : 'รูปแบบ IP ไม่ถูกต้อง',
              helperText: 'กดค้างที่สถานะเพื่อตั้งค่า',
            ),
            autofocus: true,
            onSubmitted: _isValid ? (_) => _connect() : null,
          ),
          const SizedBox(height: 8),
          Text(
            'IP ปัจจุบัน: ${widget.robotApi.effectiveTargetIp ?? "ยังไม่ตั้งค่า"}',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: _isValid ? _connect : null,
          child: const Text('เชื่อมต่อ'),
        ),
      ],
    );
  }
}
