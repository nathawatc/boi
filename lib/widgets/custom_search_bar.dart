import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  const CustomSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Row(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.search, color: Colors.grey),
          ),
          Expanded(
            child: Text(
              'ลด 30.- โค้ด WED30 (ขั้นต่ำ 300)',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          Icon(Icons.mic_none, color: Colors.grey),
          SizedBox(width: 12),
          Icon(Icons.qr_code_scanner, color: Colors.grey),
          SizedBox(width: 12),
        ],
      ),
    );
  }
}
