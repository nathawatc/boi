import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';

class OrderDetailPage extends StatelessWidget {
  final String orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final order = cart.orders.firstWhere((o) => o.id == orderId);
        
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: Text('รายละเอียดคำสั่งซื้อ #${order.id.substring(order.id.length - 6)}', 
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
            ),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Status Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        order.status == 'สำเร็จ' ? Icons.check_circle : Icons.delivery_dining, 
                        color: order.status == 'สำเร็จ' ? Colors.green : AppTheme.primaryGreen, 
                        size: 60
                      ),
                      const SizedBox(height: 16),
                      Text(order.status, 
                        style: TextStyle(
                          fontSize: 22, 
                          fontWeight: FontWeight.bold, 
                          color: order.status == 'สำเร็จ' ? Colors.green : AppTheme.primaryGreen
                        )
                      ),
                      const SizedBox(height: 8),
                      if (order.status == 'กำลังจัดส่ง')
                        Text(
                          'จะได้รับในอีกประมาณ ${order.estimatedMinutes} นาที',
                          style: TextStyle(
                            color: AppTheme.primaryGreen, 
                            fontSize: 18, 
                            fontWeight: FontWeight.bold
                          ),
                        )
                      else
                        const Text('ขอบคุณที่ใช้บริการ Boi POS!', 
                          style: TextStyle(color: Colors.grey)
                        ),
                      const SizedBox(height: 8),
                      const Text('ไรเดอร์กำลังมุ่งหน้าไปหาคุณ...', 
                        style: TextStyle(color: Colors.grey)
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
    
                // Order Items
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('รายการสินค้า', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: order.items.length,
                    itemBuilder: (context, index) {
                      final item = order.items[index];
                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text('จำนวน ${item.quantity}'),
                        trailing: Text(item.price, style: const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
    
                // Total Summary
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ราคาสุทธิ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('${order.totalAmount.toStringAsFixed(2)} บาท', 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
    
                // Confirm Button
                if (order.status != 'สำเร็จ')
                  ElevatedButton(
                    onPressed: () {
                      cart.confirmOrderReceipt(order.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ยืนยันการรับสินค้าสำเร็จ!'), backgroundColor: Colors.green),
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('ยืนยันคุณได้รับสินค้าแล้ว', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
