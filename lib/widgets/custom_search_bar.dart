import 'package:flutter/material.dart';

class CustomSearchBar extends StatefulWidget {
  final ValueChanged<String>? onChanged;
  final VoidCallback? onMicTap;
  final VoidCallback? onQrTap;

  const CustomSearchBar({
    super.key,
    this.onChanged,
    this.onMicTap,
    this.onQrTap,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
            child: TextField(
              controller: _controller,
              onChanged: widget.onChanged,
              decoration: InputDecoration(
                hintText: 'ค้นหาสินค้าหรือคูปอง...',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                isDense: true,
              ),
            ),
          ),
          InkWell(
            onTap: widget.onMicTap,
            child: Icon(Icons.mic_none, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: widget.onQrTap,
            child: Icon(Icons.qr_code_scanner, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
