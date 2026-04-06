import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;

  const SectionHeader({super.key, required this.title, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (onViewAll != null)
            InkWell(
              onTap: onViewAll,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  const Text('ดูทั้งหมด', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                ],
              ),
            )
          else
            const Row(
              children: [
                const Text('ดูทั้งหมด', style: TextStyle(color: Colors.grey, fontSize: 14)),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
        ],
      ),
    );
  }
}
