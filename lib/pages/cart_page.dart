import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import 'payment_page.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ตะกร้าสินค้า', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: cart.items.isEmpty
          ? SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text('ไม่มีสินค้าในตระกร้า', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  Text(item.price, style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Text('x ${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => cart.removeItem(item.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'กรอกรหัสคูปอง',
                            prefixIcon: const Icon(Icons.confirmation_num_outlined, color: Colors.blueGrey),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          onSubmitted: (value) {
                            if (cart.applyCoupon(value)) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ใช้คูปองสำเร็จ!'), backgroundColor: Colors.green));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('รหัสคูปองไม่ถูกต้อง'), backgroundColor: Colors.red));
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          _showCouponSheet(context, cart);
                        },
                        child: Text('ดูคูปอง', style: TextStyle(color: AppTheme.primarySky, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                if (cart.appliedCoupon != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Text('คูปองที่ใช้: ${cart.appliedCoupon!.title}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16, color: Colors.green),
                            onPressed: () => cart.removeCoupon(),
                          ),
                        ],
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('ราคารวม', style: TextStyle(fontSize: 14, color: Colors.grey)),
                            Text('${cart.subTotal.toStringAsFixed(2)} บาท', style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                        if (cart.discountAmount > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('ส่วนลด', style: TextStyle(fontSize: 14, color: Colors.redAccent)),
                                Text('-${cart.discountAmount.toStringAsFixed(2)} บาท', style: const TextStyle(fontSize: 14, color: Colors.redAccent)),
                              ],
                            ),
                          ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('ราคาสุทธิ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('${cart.totalAmount.toStringAsFixed(2)} บาท',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentPage(totalAmount: cart.totalAmount),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('ชำระเงิน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showCouponSheet(BuildContext context, CartProvider cart) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final collected = cart.collectedCoupons;
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('คูปองของฉัน', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              if (collected.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text('คุณยังไม่มีคูปองที่เก็บไว้\nไปเลือกเก็บที่หน้าแรกได้เลย!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: collected.length,
                    itemBuilder: (context, index) {
                      final coupon = collected[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.confirmation_num, color: Colors.blue),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(coupon.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('รหัส: ${coupon.code}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                cart.applyCoupon(coupon.code);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ใช้คูปองสำเร็จ!'), backgroundColor: Colors.green));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primarySky,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                minimumSize: const Size(60, 32),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('ใช้เลย', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
