import 'package:flutter/material.dart';

class PromotionItem extends StatelessWidget {
  const PromotionItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange.shade50,
              ),
              child: const Center(child: Icon(Icons.flash_on, color: Colors.orange)),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'โปรแรง 1 แถม 1',
            style: TextStyle(fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
