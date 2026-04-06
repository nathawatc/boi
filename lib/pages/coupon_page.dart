import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';

class CouponPage extends StatelessWidget {
  const CouponPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: const Text('คูปองส่วนลด', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          final available = cart.availableCoupons;

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            children: [
              // Banner Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.blue, size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('สะสมคูปองเพื่อประหยัดมากขึ้น', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey)),
                          Text('คุณมีคูปองที่เก็บแล้ว ${cart.collectedCoupons.length} ใบ', style: const TextStyle(fontSize: 13, color: Colors.blue)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('คูปองแนะนำสำหรับคุณ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),

              // Coupons List
              ...available.map((coupon) => _LargeCouponCard(coupon: coupon)).toList(),

              const SizedBox(height: 20),
              Center(
                child: Text(
                  'คูปองใหม่จะเข้าทุกสัปดาห์ อย่าลืมมาตรวจเช็คนะ!',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}

class _LargeCouponCard extends StatelessWidget {
  final Coupon coupon;

  const _LargeCouponCard({required this.coupon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          Row(
            children: [
              // Left Cutout Part
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primarySky.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${coupon.discountAmount.toInt()}.-',
                      style: TextStyle(color: AppTheme.primarySky, fontWeight: FontWeight.bold, fontSize: 28),
                    ),
                    const Text('OFF', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w500, fontSize: 12)),
                  ],
                ),
              ),

              // Divider (Dashed)
              Container(
                width: 1,
                height: 70,
                color: Colors.grey.shade200,
              ),

              // Right Details Part
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        coupon.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'เมื่อซื้อครบ ${coupon.minSpend.toInt()}.-',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.history, color: Colors.grey.shade400, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            coupon.isExpired ? 'หมดอายุแล้ว' : 'ใช้ได้ถึง ${coupon.expiryDateFormatted}',
                            style: TextStyle(
                              color: coupon.isExpired ? Colors.red : Colors.grey.shade400,
                              fontSize: 10
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: (coupon.isCollected || coupon.isExpired)
                              ? null
                              : () {
                                context.read<CartProvider>().collectCoupon(coupon.code);
                              },
                            style: TextButton.styleFrom(
                              backgroundColor: coupon.isCollected ? Colors.grey.shade100 : (coupon.isExpired ? Colors.grey.shade300 : AppTheme.primarySky.withOpacity(0.1)),
                              foregroundColor: coupon.isCollected ? Colors.grey : (coupon.isExpired ? Colors.grey.shade500 : AppTheme.primarySky),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: Text(
                              coupon.isCollected ? 'เก็บแล้ว' : (coupon.isExpired ? 'หมดอายุ' : 'เก็บคูปอง'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Ticket Cutouts (Half circles on top and bottom of divider)
          Positioned(
            left: 95,
            top: -5,
            child: CircleAvatar(radius: 5, backgroundColor: Color(0xFFF5F7F5)),
          ),
          Positioned(
            left: 95,
            bottom: -5,
            child: CircleAvatar(radius: 5, backgroundColor: Color(0xFFF5F7F5)),
          ),
        ],
      ),
    );
  }
}
