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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
                color: imageUrl == null ? (icon != null ? Colors.blue.shade50 : (color ?? Colors.grey.shade100)) : (color ?? Colors.grey.shade200),
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
                        color: icon != null ? Colors.blue : Colors.grey,
                        size: 50
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
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
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
