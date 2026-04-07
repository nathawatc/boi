import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/product_detail_page.dart';
import '../providers/cart_provider.dart';

class ProductCard extends StatelessWidget {
  final String name;
  final String price;
  final String? imageUrl;
  final IconData? icon;
  final Color? color;

  const ProductCard({
    super.key,
    this.name = 'ชื่อสินค้าตัวอย่าง...',
    this.price = '45 บาท',
    this.imageUrl,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              id: name,
              name: name,
              price: price,
              imageUrl: imageUrl ?? '',
              icon: icon,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: imageUrl == null
                    ? (icon != null
                        ? Theme.of(context).colorScheme.primaryContainer
                        : (color ?? Theme.of(context).colorScheme.surfaceContainerHighest))
                    : (color ?? Theme.of(context).colorScheme.surfaceContainerHighest),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: imageUrl != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(imageUrl!, fit: BoxFit.cover),
                    )
                  : Center(
                      child: Icon(
                        icon ?? Icons.image_outlined,
                        color: icon != null
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 50,
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        // WARNING: Using name as product ID can cause collisions if products have duplicate names
                        // TODO: Add unique ID field to product data model
                        context.read<CartProvider>().addItem(
                          name,
                          name,
                          price
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('เพิ่มลงรถเข็นแล้ว!'),
                            duration: Duration(milliseconds: 500),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
