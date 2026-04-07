import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/cart_provider.dart';
import '../services/robot_api.dart';
import '../widgets/robot_status_indicator.dart';
import '../widgets/manual_ip_input_dialog.dart';

class PaymentPage extends StatefulWidget {
  final double totalAmount;
  final List<CartItem> orderItems;

  const PaymentPage({super.key, required this.totalAmount, required this.orderItems});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  int _selectedAddressIndex = 0; // 0 for Home, 1 for Office
  String _selectedPaymentMethod = 'QR';
  bool _isSendingToRobot = false;

  final List<Map<String, String>> _addresses = [
    {
      'type': 'Home',
      'detail': 'เลขที่ 69/101 ห้องA0901 สาขา คอนโดตัวอย่าง',
      'icon': 'home',
    },
    {
      'type': 'Office',
      'detail': 'เลขที่ 108 ชั้น 29 สาขา อาคารตัวอย่าง',
      'icon': 'work',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('ชำระเงิน', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Robot Connection Status
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RobotStatusIndicator(
                    robotApi: context.read<RobotApi>(),
                    showRefreshButton: false,
                    showTapToDiscover: true,
                  ),
                  const SizedBox(width: 8),
                  // Manual IP button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _showManualIpDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_location,
                              size: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'ระบุ IP',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Amount Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                children: [
                  Text('ยอดชำระทั้งหมด', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.totalAmount.toStringAsFixed(2)} บาท',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Select Delivery Address
            const Text(
              'เลือกที่อยู่จัดส่ง',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...List.generate(_addresses.length, (index) {
              final addr = _addresses[index];
              final isSelected = _selectedAddressIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedAddressIndex = index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          addr['icon'] == 'home' ? Icons.home_rounded : Icons.work_rounded,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              addr['type']!,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              addr['detail']!,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: AppTheme.primaryGreen)
                      else
                        Icon(Icons.circle_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),

            // Order Items Summary
            const Text(
              'รายการของคุณ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: widget.orderItems.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${item.name} x ${item.quantity}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                        Text(item.price, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 30),

            // Payment Methods
            const Text(
              'เลือกช่องทางการชำระเงิน',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildPaymentOption(
              context,
              id: 'QR',
              icon: Icons.qr_code_scanner,
              label: 'Thai QR Payment',
              subtitle: 'พร้อมเพย์, แอพธนาคาร',
              color: const Color(0xFF1D3C6A),
            ),
            _buildPaymentOption(
              context,
              id: 'Wallet',
              icon: Icons.account_balance_wallet_outlined,
              label: 'TrueMoney Wallet',
              subtitle: 'ชำระผ่านวอลเล็ท',
              color: Colors.orange,
            ),
            _buildPaymentOption(
              context,
              id: 'Card',
              icon: Icons.credit_card_outlined,
              label: 'บัตรเครดิต / เดบิต',
              subtitle: 'Visa, Mastercard, JCB',
              color: Colors.blue,
            ),
            _buildPaymentOption(
              context,
              id: 'Cash',
              icon: Icons.money_outlined,
              label: 'เงินสด',
              subtitle: 'ชำระเมื่อรับสินค้า',
              color: Colors.green,
            ),

            const SizedBox(height: 40),

            // Bottom Action
            Consumer<RobotApi>(
              builder: (context, robotApi, child) {
                final isConnected = robotApi.isConnected;

                return ElevatedButton(
                  onPressed: isConnected && !_isSendingToRobot
                      ? () => _handlePaymentConfirmation(context)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isConnected ? AppTheme.primaryGreen : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isSendingToRobot
                      ? const SizedBox(
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isConnected ? Icons.check_circle : Icons.wifi_off,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isConnected ? 'ยืนยันรายการ' : 'หุ่นยนต์ยังไม่เชื่อมต่อ',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                );
              },
            ),

            // Helper text
            Consumer<RobotApi>(
              builder: (context, robotApi, child) {
                if (!robotApi.isConnected) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      '💡 แตะที่ตัวแสดงสถานะด้านบนเพื่อค้นหาหุ่นยนต์',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    BuildContext context, {
    required String id,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
  }) {
    final isSelected = _selectedPaymentMethod == id;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? AppTheme.primaryGreen : Colors.transparent, width: 2),
      ),
      child: ListTile(
        onTap: () => setState(() => _selectedPaymentMethod = id),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
        trailing: isSelected
          ? Icon(Icons.check_circle, color: AppTheme.primaryGreen)
          : Icon(Icons.circle_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, CartProvider cartProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Icon(Icons.check_circle, color: AppTheme.gradientEnd, size: 100),
            const SizedBox(height: 24),
            const Text('ชำระเงินสำเร็จ!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('ขอบคุณที่ใช้บริการ Boi นะครับ\nไรเดอร์กำลังเตรียมจัดส่งสินค้าให้คุณ',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                cartProvider.checkout();
                Navigator.pop(context); // Close dialog
                // Safely navigate back: pop until we reach HomePage
                _navigateToHomePage(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gradientEnd.withValues(alpha: 0.8),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('กลับสู่หน้าหลัก', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, CartProvider cartProvider, String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Icon(Icons.error_outline, color: Colors.red, size: 100),
            const SizedBox(height: 24),
            const Text('เกิดข้อผิดพลาด', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'ไม่สามารถเชื่อมต่อหุ่นยนต์ได้\n$errorMessage',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              'คำสั่งซื้อของคุณจะถูกบันทึกและจัดส่งเมื่อหุ่นยนต์พร้อม',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                cartProvider.checkout();
                Navigator.pop(context); // Close dialog
                // Safely navigate back: pop until we reach HomePage
                _navigateToHomePage(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('เข้าใจแล้ว', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  /// Safely navigate back to the home page by popping until reaching root
  void _navigateToHomePage(BuildContext context) {
    // FIX: Use popUntil(isFirst) instead of magic number popCount < 3
    // This is more robust and doesn't depend on navigation stack depth
    Navigator.of(context).popUntil((route) => route.isFirst);

    // Set tab index to 0 (Home) after navigation
    if (mounted) {
      context.read<CartProvider>().setTabIndex(0);
    }
  }

  void _handlePaymentConfirmation(BuildContext context) {
    final robotApi = context.read<RobotApi>();

    // Double-check connection status
    if (!robotApi.isConnected) {
      _showConnectionRequiredDialog(context);
      return;
    }

    // Proceed with payment
    _processPayment(context);
  }

  void _showManualIpDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => ManualIpInputDialog(
        robotApi: context.read<RobotApi>(),
      ),
    );
  }

  Future<void> _processPayment(BuildContext context) async {
    final robotApi = context.read<RobotApi>();

    setState(() {
      _isSendingToRobot = true;
    });

    try {
      // Send command to robot via new API
      final response = await robotApi.moveForward();

      // Handle result with mounted check
      if (!mounted) return;

      // FIX: Removed // ignore: use_build_context_synchronously
      // Now properly checking mounted before using context
      final cartProvider = context.read<CartProvider>();

      if (response.success) {
        debugPrint('Robot command successful');
        _showSuccessDialog(context, cartProvider);
      } else {
        debugPrint('Robot command failed: ${response.message}');
        _showErrorDialog(context, cartProvider, response.message);
      }
    } catch (e) {
      debugPrint('Error sending robot command: $e');
      // Handle error with mounted check
      if (mounted) {
        final cartProvider = context.read<CartProvider>();
        // FIX: Show user-friendly message instead of raw exception
        _showErrorDialog(context, cartProvider, 'เกิดข้อผิดพลาดในการเชื่อมต่อหุ่นยนต์');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingToRobot = false;
        });
      }
    }
  }

  void _showConnectionRequiredDialog(BuildContext context) {
    final robotApi = context.read<RobotApi>();
    bool isDiscovering = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Icon(
                robotApi.isConnected ? Icons.check_circle : Icons.wifi_off,
                color: robotApi.isConnected ? Colors.green : Colors.orange,
                size: 100,
              ),
              const SizedBox(height: 24),
              Text(
                robotApi.isConnected
                    ? 'เชื่อมต่อสำเร็จ!'
                    : 'ต้องการการเชื่อมต่อหุ่นยนต์',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (robotApi.isConnected) ...[
                Text(
                  'หุ่นยนต์พร้อมทำงานแล้ว',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16),
                ),
              ] else ...[
                Text(
                  isDiscovering
                      ? 'กำลังค้นหาหุ่นยนต์บนเครือข่าย...'
                      : 'กรุณาตรวจสอบว่าหุ่นยนต์เปิดอยู่และเชื่อมต่อกับ WiFi เดียวกัน',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16),
                ),
                if (robotApi.lastKnownIp != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'IP: ${robotApi.lastKnownIp}',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 32),
              if (!robotApi.isConnected) ...[
                ElevatedButton(
                  onPressed: isDiscovering
                      ? null
                      : () async {
                          setDialogState(() {
                            isDiscovering = true;
                          });

                          final ip = await robotApi.discoverRobot();

                          setDialogState(() {
                            isDiscovering = false;
                          });

                          // If found, close dialog and proceed
                          if (ip != null) {
                            // Capture context before async gap
                            final currentContext = context;
                            if (currentContext.mounted) {
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }
                              _processPayment(currentContext);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: isDiscovering
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'ค้นหาหุ่นยนต์',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: Text(
                    'ยกเลิก',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16),
                  ),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _processPayment(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'ยืนยันรายการ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
