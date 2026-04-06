import 'package:flutter/material.dart';
import '../pages/category_products_page.dart';

class CategoryItem extends StatelessWidget {
  final String title;
  final IconData icon;

  const CategoryItem({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(32),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryProductsPage(categoryName: title),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
