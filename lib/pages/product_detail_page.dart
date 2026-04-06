import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/cart_provider.dart';

class ProductDetailPage extends StatefulWidget {
  final String id;
  final String name;
  final String price;
  final String? imageUrl;
  final IconData? icon;

  const ProductDetailPage({
    super.key,
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.icon,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _quantity = 1;

  void _increment() {
    setState(() {
      _quantity++;
    });
  }

  void _decrement() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive expanded height based on screen height
          final screenHeight = constraints.maxHeight;
          final expandedHeight = (screenHeight * 0.35).clamp(200.0, 300.0);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: expandedHeight,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                      ? Image.network(widget.imageUrl!, fit: BoxFit.cover)
                      : Container(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Center(
                            child: Icon(
                              widget.icon ?? Icons.fastfood_rounded,
                              size: (expandedHeight * 0.5).clamp(100.0, 150.0),
                              color: AppTheme.primarySky,
                            ),
                          ),
                        ),
                ),
                backgroundColor: AppTheme.primarySky,
              ),
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.name,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            widget.price,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'รายละเอียดสินค้า',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'พบกับเมนูยอดนิยมที่ผ่านการคัดสรรมาอย่างดีที่สุด วัตถุดิบคุณภาพดี สะอาด ปลอดภัย และอร่อย ถูกใจแน่นอน สั่งเลยวันนี้เพื่อรับโปรโมชั่นพิเศษ!',
                        style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5),
                      ),
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 32),
                      const Text(
                        'ข้อมูลโภชนาการ (โดยประมาณ)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildNutritionRow('พลังงาน', '250 kcal'),
                      _buildNutritionRow('ไขมันทั้งหมด', '12g'),
                      _buildNutritionRow('คาร์โบไฮเดรต', '25g'),
                      _buildNutritionRow('โปรตีน', '8g'),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(color: Theme.of(context).colorScheme.shadow.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _decrement,
                      icon: const Icon(Icons.remove)
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      onPressed: _increment,
                      icon: Icon(Icons.add, color: AppTheme.primarySky)
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    context.read<CartProvider>().addItem(
                      widget.id,
                      widget.name,
                      widget.price,
                      quantity: _quantity
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('เพิ่ม ${widget.name} จำนวน $_quantity ลงในตะกร้าแล้ว!'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Text('เพิ่มลงตะกร้า', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
