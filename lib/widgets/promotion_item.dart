import 'package:flutter/material.dart';

class PromotionItem extends StatelessWidget {
  const PromotionItem({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive sizing based on available width
        final iconSize = constraints.maxWidth < 400 ? 35.0 : 40.0;
        final fontSize = constraints.maxWidth < 400 ? 10.0 : 11.0;

        return Container(
          width: 80.0.clamp(70.0, 90.0),
          margin: const EdgeInsets.only(right: 12),
          child: Column(
            children: [
              CircleAvatar(
                radius: iconSize,
                backgroundColor: Theme.of(context).colorScheme.surface,
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.flash_on,
                      color: Theme.of(context).colorScheme.primary,
                      size: iconSize * 0.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'โปรแรง 1 แถม 1',
                style: TextStyle(
                  fontSize: fontSize,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}
