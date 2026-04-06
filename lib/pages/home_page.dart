import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/cart_provider.dart';
import '../services/robot_api.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/section_header.dart';
import '../widgets/promotion_item.dart';
import '../widgets/category_item.dart';
import '../widgets/product_card.dart';
import '../widgets/frequent_product_item.dart';
import '../widgets/robot_status_indicator.dart';
import 'cart_page.dart';
import 'order_history_page.dart';
import 'coupon_page.dart';
import 'robot_control_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Widget> get _pages => [
    const HomeContent(),
    const OrderHistoryPage(),
    const CartPage(),
    const CouponPage(),
    const MoreMenuPage(),
  ];

  void _onItemTapped(int index) {
    context.read<CartProvider>().setTabIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = context.watch<CartProvider>().currentTabIndex;
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: _pages[selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        elevation: 10,
        currentIndex: selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryGreen,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าหลัก'),
          BottomNavigationBarItem(
            icon: Consumer<CartProvider>(
              builder: (context, cart, child) {
                final pendingCount = cart.orders.where((o) => o.status == 'กำลังจัดส่ง').length;
                return Badge(
                  isLabelVisible: pendingCount > 0,
                  label: Text('$pendingCount'),
                  child: const Icon(Icons.list_alt),
                );
              },
            ),
            label: 'รายการซื้อ',
          ),
          BottomNavigationBarItem(
            icon: Consumer<CartProvider>(
              builder: (context, cart, child) => Badge(
                isLabelVisible: cart.itemCount > 0,
                label: Text('${cart.itemCount}'),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
            ),
            label: 'รถเข็น',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'คูปอง'),
          const BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'อื่น ๆ'),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Redesigned Header to 7-Eleven style
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final isSmallScreen = screenWidth < 360;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Top Action Icons Row (Removed back button, Robot on left)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            // Robot Status Indicator - Responsive, on the left
                            Flexible(
                              child: RobotStatusIndicator(
                                robotApi: context.read<RobotApi>(),
                                showRefreshButton: !isSmallScreen,
                                showTapToDiscover: true,
                                showIp: !isSmallScreen,
                              ),
                            ),
                            const Spacer(),
                            _CircularIcon(icon: Icons.favorite_border),
                            if (!isSmallScreen) ...[
                              const SizedBox(width: 12),
                              _CircularIcon(label: 'TH'),
                              const SizedBox(width: 12),
                            ],
                            const SizedBox(width: 12),
                            _CircularIcon(icon: Icons.person_outline),
                          ],
                        ),
                      ),

                      // 2. Delivery Info Column
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ส่งทันที',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 20 : 24,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '1 ตำบล นาป่า อำเภอเมืองชลบุรี ชลบุรี',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmallScreen ? 14 : 16,
                                      fontWeight: FontWeight.w400
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.keyboard_arrow_down, color: Colors.white.withOpacity(0.8), size: 18),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // 3. Search Bar
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: CustomSearchBar(),
                      ),

                      const SizedBox(height: 16),

                      // 4. Main Service Cards (Food & Mart)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _ServiceCard(
                                title: 'Drink',
                                badge: 'ลด ฿100',
                                badgeColor: Colors.redAccent,
                                icon: Icons.local_drink_rounded,
                                isSpecial: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ServiceCard(
                                title: 'Mart',
                                badge: 'ส่งฟรี!',
                                badgeColor: Colors.pinkAccent,
                                icon: Icons.storefront_rounded,
                                isSpecial: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 16),

              // Coupon Section (Based on Reference Image)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('คูปองส่วนลด', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    TextButton(
                      onPressed: () {},
                      child: const Row(
                        children: [
                          Text('ดูทั้งหมด', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          Icon(Icons.chevron_right, color: Colors.grey, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Consumer<CartProvider>(
                builder: (context, cart, child) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      // Responsive height based on screen size
                      final height = constraints.maxWidth < 360 ? 100.0 : 110.0;
                      return SizedBox(
                        height: height,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: cart.availableCoupons.length,
                          itemBuilder: (context, index) {
                            final coupon = cart.availableCoupons[index];
                            return _CouponCard(coupon: coupon);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 12),

              // Frequently Bought Section
              const SectionHeader(title: 'สินค้าที่ซื้อบ่อย'),
              SizedBox(
                height: 180,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    const FrequentProductItem(name: 'น้ำดื่ม Boi 600ml', price: '7.-', icon: Icons.local_drink),
                    const FrequentProductItem(name: 'แซนวิชอบร้อน', price: '29.-', icon: Icons.breakfast_dining),
                    const FrequentProductItem(name: 'กาแฟออลคาเฟ่', price: '35.-', icon: Icons.coffee),
                    const FrequentProductItem(name: 'เป๊ปซี่ 430ml', price: '16.-', icon: Icons.local_drink_rounded),
                    const FrequentProductItem(name: 'เลย์ มันฝรั่งแท้', price: '20.-', icon: Icons.fastfood),
                    const FrequentProductItem(name: 'นมสดพาสเจอร์ไรซ์', price: '12.-', icon: Icons.egg),
                    const FrequentProductItem(name: 'ไข่ต้มปอกเปลือก', price: '10.-', icon: Icons.egg_alt),
                    const FrequentProductItem(name: 'ข้าวกระเพราไก่', price: '45.-', icon: Icons.lunch_dining),
                    const FrequentProductItem(name: 'มาม่าคัพ รสต้มยำ', price: '15.-', icon: Icons.soup_kitchen),
                    const FrequentProductItem(name: 'น้ำส้ม 100%', price: '25.-', icon: Icons.local_bar),
                    const FrequentProductItem(name: 'ขนมปังแผ่น', price: '22.-', icon: Icons.bakery_dining),
                    const FrequentProductItem(name: 'เยลลี่ผลไม้', price: '10.-', icon: Icons.icecream),
                    const FrequentProductItem(name: 'น้ำแร่ธรรมชาติ', price: '15.-', icon: Icons.opacity),
                    const FrequentProductItem(name: 'เบอร์เกอร์หมู', price: '32.-', icon: Icons.lunch_dining_rounded),
                  ],
                ),
              ),

              // Promotions Section
              const SectionHeader(title: 'โปรโมชั่น'),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 5,
                  itemBuilder: (context, index) => const PromotionItem(),
                ),
              ),

              // Categories Section
              const SectionHeader(title: 'หมวดหมู่สินค้า'),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final crossAxisCount = width > 600 ? 6 : 5;
                  final childAspectRatio = width > 600 ? 0.9 : 0.85;

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: childAspectRatio,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    mainAxisSpacing: 8,
                    children: const [
                      CategoryItem(title: 'อาหาร', icon: Icons.lunch_dining),
                      CategoryItem(title: 'เครื่องดื่ม', icon: Icons.local_drink),
                      CategoryItem(title: 'ไอศกรีม', icon: Icons.icecream),
                      CategoryItem(title: 'เบเกอรี่', icon: Icons.breakfast_dining),
                      CategoryItem(title: 'ของสด', icon: Icons.apple),
                      CategoryItem(title: 'สุขภาพ', icon: Icons.health_and_safety),
                      CategoryItem(title: 'ของใช้', icon: Icons.house_siding),
                      CategoryItem(title: 'นมและไข่', icon: Icons.egg),
                      CategoryItem(title: 'แช่แข็ง', icon: Icons.ac_unit),
                      CategoryItem(title: 'อื่นๆ', icon: Icons.more_horiz),
                    ],
                  );
                },
              ),

              // Social Trends
              const SectionHeader(title: 'ติดกระแสโซเชียล'),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: ProductCard(name: 'ยำยำช้างน้อย', price: '5 บาท', icon: Icons.soup_kitchen)),
                    SizedBox(width: 12),
                    Expanded(child: ProductCard(name: 'ข้าวเหนียวหมูปิ้ง', price: '35 บาท', icon: Icons.set_meal)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: ProductCard(name: 'นมเปรี้ยวบีทาเก้น', price: '12 บาท', icon: Icons.local_drink)),
                    SizedBox(width: 12),
                    Expanded(child: ProductCard(name: 'ขนมจีบกุ้ง', price: '25 บาท', icon: Icons.bakery_dining)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: ProductCard(name: 'น้ำยาปรับผ้านุ่ม', price: '10 บาท', icon: Icons.wash)),
                    SizedBox(width: 12),
                    Expanded(child: ProductCard(name: 'สบู่ก้อน นกแก้ว', price: '18 บาท', icon: Icons.clean_hands)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: ProductCard(name: 'กาแฟเบอร์ดี้', price: '16 บาท', icon: Icons.coffee_maker)),
                    SizedBox(width: 12),
                    Expanded(child: ProductCard(name: 'ถุงขยะ ขนาดกลาง', price: '20 บาท', icon: Icons.delete_outline)),
                  ],
                ),
              ),

              const SizedBox(height: 100), // Bottom padding
            ],
          ),
        ),
      ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final String badge;
  final Color? badgeColor;
  final String? iconUrl;
  final IconData? icon;
  final bool isSpecial;

  const _ServiceCard({
    required this.title,
    required this.badge,
    this.badgeColor,
    this.iconUrl,
    this.icon,
    this.isSpecial = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8)
          ),
        ],
      ),
      child: Stack(
        children: [
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey
                  ),
                ),
              ],
            ),
          ),
          // Large floating icon
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (title == 'Drink' ? Colors.blue.shade50 : Colors.pink.shade50).withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: icon != null
                ? Icon(
                    icon,
                    size: 45,
                    color: title == 'Drink' ? AppTheme.primarySky : Colors.pink,
                  )
                : Image.network(
                    iconUrl!,
                    width: 45,
                    height: 45,
                    fit: BoxFit.contain,
                  ),
            ),
          ),
          // Elegant Badge
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (badgeColor ?? Colors.red).withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final Coupon coupon;

  const _CouponCard({required this.coupon});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Make coupon card responsive
        final maxWidth = constraints.maxWidth;
        final cardWidth = (maxWidth * 0.75).clamp(240.0, 280.0);

        return Container(
          width: cardWidth,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Row(
                  children: [
                    // Left Ticket Section
                    Container(
                      width: 80,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primarySky.withOpacity(0.1), Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: FittedBox(
                          child: Text(
                            '${coupon.discountAmount.toInt()}.-',
                            style: TextStyle(
                              color: AppTheme.primarySky,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              letterSpacing: -1
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Dashed Line Simulation (using CustomPaint or Row of small blocks)
                    Container(
                      width: 1,
                      height: 60,
                      color: Colors.grey.shade200,
                    ),
                    // Right Section
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              coupon.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'เมื่อซื้อครบ ${coupon.minSpend.toInt()} บาท',
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: coupon.isCollected
                                  ? null
                                  : () {
                                    context.read<CartProvider>().collectCoupon(coupon.code);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('เก็บคูปอง ${coupon.code} สำเร็จ!'), backgroundColor: Colors.green),
                                    );
                                  },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: coupon.isCollected ? Colors.grey.shade200 : AppTheme.primarySky,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  minimumSize: const Size(80, 28),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(
                                  coupon.isCollected ? 'เก็บแล้ว' : 'เก็บเลย',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: coupon.isCollected ? Colors.grey : Colors.white
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Ticket Cut-outs (Top & Bottom)
                Positioned(
                  left: 72,
                  top: -8,
                  child: _buildCutOut(),
                ),
                Positioned(
                  left: 72,
                  bottom: -8,
                  child: _buildCutOut(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCutOut() {
    return Container(
      width: 16,
      height: 16,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC), // Same as background
        shape: BoxShape.circle,
      ),
    );
  }
}

class _CircularIcon extends StatelessWidget {
  final IconData? icon;
  final String? label;

  const _CircularIcon({this.icon, this.label});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.white.withOpacity(0.2),
      child: icon != null
        ? Icon(icon, color: Colors.white, size: 20)
        : Text(label!, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

/// More menu page with list of options
class MoreMenuPage extends StatelessWidget {
  const MoreMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: ListView(
        children: [
          const SizedBox(height: 16),
          _MoreMenuItem(
            icon: Icons.gamepad,
            iconColor: AppTheme.primaryGreen,
            title: 'ควบคุมหุ่นยนต์ด้วยมือ',
            subtitle: 'ควบคุมการเคลื่อนที่ของหุ่นยนต์',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RobotControlPage(),
                ),
              );
            },
          ),
          const Divider(height: 1, indent: 72),
          _MoreMenuItem(
            icon: Icons.settings,
            iconColor: Colors.grey,
            title: 'ตั้งค่า',
            subtitle: 'กำลังพัฒนาเร็วๆ นี้',
            enabled: false,
          ),
          const Divider(height: 1, indent: 72),
          _MoreMenuItem(
            icon: Icons.help_outline,
            iconColor: Colors.grey,
            title: 'ช่วยเหลือ',
            subtitle: 'กำลังพัฒนาเร็วๆ นี้',
            enabled: false,
          ),
        ],
      ),
    );
  }
}

class _MoreMenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  const _MoreMenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: enabled ? onTap : null,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: enabled ? Colors.black87 : Colors.grey,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 13),
      ),
      trailing: enabled
          ? const Icon(Icons.chevron_right, color: Colors.grey)
          : null,
      enabled: enabled,
    );
  }
}
