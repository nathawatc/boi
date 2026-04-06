import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/cart_provider.dart';

class PaymentPage extends StatefulWidget {
  final double totalAmount;

  const PaymentPage({super.key, required this.totalAmount});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  int _selectedAddressIndex = 0; // 0 for Home, 1 for Office
  String _selectedPaymentMethod = 'QR';
  late final List<CartItem> _orderItems;

  @override
  void initState() {
    super.initState();
    // Capture cart items before they're cleared
    _orderItems = List.from(context.read<CartProvider>().items);
  }

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
      backgroundColor: const Color(0xFFF8FAFC),
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
            // Amount Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                children: [
                  const Text('ยอดชำระทั้งหมด', style: TextStyle(color: Colors.grey, fontSize: 16)),
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
                    color: Colors.white,
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
                          color: AppTheme.primaryGreen.withOpacity(0.1),
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
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: AppTheme.primaryGreen)
                      else
                        const Icon(Icons.circle_outlined, color: Colors.grey),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: _orderItems.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${item.name} x ${item.quantity}', style: const TextStyle(color: Colors.black87)),
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
            ElevatedButton(
              onPressed: () async {
                // Store cart provider reference before async operation
                final cartProvider = context.read<CartProvider>();

                try {
                  // Send UDP Packet to Robot (Broadcast to local network)
                  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
                  socket.broadcastEnabled = true;

                  // UDP is a fire-and-forget protocol (no guaranteed delivery).
                  // To fix packet loss without adding complex TCP handshakes,
                  // we send the packet 3 times with a tiny 50ms delay between them.
                  // This is standard practice in IoT remote controls.
                  for (int i = 0; i < 3; i++) {
                    socket.send('F'.codeUnits, InternetAddress('255.255.255.255'), 2001);
                    await Future.delayed(const Duration(milliseconds: 50));
                  }

                  debugPrint('Successfully broadcasted UDP packet "F" to Robot (3x Redundancy)');
                  socket.close();
                } catch (e) {
                  debugPrint('Failed to send UDP packet: $e');
                }

                if (!mounted) return;
                _showSuccessDialog(context, cartProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('ยืนยันรายการ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? AppTheme.primaryGreen : Colors.transparent, width: 2),
      ),
      child: ListTile(
        onTap: () => setState(() => _selectedPaymentMethod = id),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        trailing: isSelected
          ? Icon(Icons.check_circle, color: AppTheme.primaryGreen)
          : const Icon(Icons.circle_outlined, color: Colors.grey),
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
            const Text('ขอบคุณที่ใช้บริการ Boi นะครับ\nไรเดอร์กำลังเตรียมจัดส่งสินค้าให้คุณ',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                cartProvider.checkout();
                // Sequence of pops
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Back to cart

                // Go to Order History Tab (Index 1)
                cartProvider.setTabIndex(1);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gradientEnd.withOpacity(0.8),
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
}
