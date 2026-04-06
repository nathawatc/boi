import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/product_detail_page.dart';
import '../providers/cart_provider.dart';

class FrequentProductItem extends StatelessWidget {
  final String name;
  final String price;
  final String? imageUrl;
  final IconData? icon;

  const FrequentProductItem({
    super.key,
    required this.name,
    required this.price,
    this.imageUrl,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive width based on available space
        final itemWidth = constraints.maxWidth < 400 ? 130.0 : 140.0;

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
            width: itemWidth,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10, offset: const Offset(0, 5)
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image/Icon placeholder
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: imageUrl == null ? (icon != null ? Colors.blue.shade50 : Colors.grey.shade100) : Colors.grey.shade100,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: imageUrl != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.network(imageUrl!, fit: BoxFit.cover, width: double.infinity),
                        )
                      : Center(
                          child: Icon(
                            icon ?? Icons.shopping_bag_outlined,
                            color: icon != null ? Colors.blue : Colors.grey,
                            size: 45
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            price,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              context.read<CartProvider>().addItem(name, name, price);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('เพิ่ม $name แล้ว!'),
                                  duration: const Duration(milliseconds: 500),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add, color: Colors.white, size: 14),
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
      },
    );
  }
}
