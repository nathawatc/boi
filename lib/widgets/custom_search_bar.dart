import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  const CustomSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          Expanded(
            child: Text(
              'ลด 30.- โค้ด WED30 (ขั้นต่ำ 300)',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
            ),
          ),
          Icon(Icons.mic_none, color: Theme.of(context).colorScheme.onSurfaceVariant),
          SizedBox(width: 12),
          Icon(Icons.qr_code_scanner, color: Theme.of(context).colorScheme.onSurfaceVariant),
          SizedBox(width: 12),
        ],
      ),
    );
  }
}
