import 'package:flutter/material.dart';
import '../services/robot_api.dart';

/// A reusable dialog for manually entering a robot IP address
class ManualIpInputDialog extends StatefulWidget {
  final RobotApi robotApi;

  const ManualIpInputDialog({super.key, required this.robotApi});

  @override
  State<ManualIpInputDialog> createState() => _ManualIpInputDialogState();
}

class _ManualIpInputDialogState extends State<ManualIpInputDialog> {
  final _ipController = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
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
      if (mounted) {
        Navigator.of(context).pop();
      }
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
