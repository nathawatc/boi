import 'package:flutter/material.dart';

class DeliveryToggle extends StatefulWidget {
  final ValueChanged<bool>? onChanged;
  final bool immediateDelivery;

  const DeliveryToggle({
    super.key,
    this.onChanged,
    this.immediateDelivery = true,
  });

  @override
  State<DeliveryToggle> createState() => _DeliveryToggleState();
}

class _DeliveryToggleState extends State<DeliveryToggle> {
  late bool _immediateDelivery;

  @override
  void initState() {
    super.initState();
    _immediateDelivery = widget.immediateDelivery;
  }

  @override
  void didUpdateWidget(DeliveryToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.immediateDelivery != widget.immediateDelivery) {
      _immediateDelivery = widget.immediateDelivery;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _immediateDelivery = true);
                widget.onChanged?.call(true);
              },
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _immediateDelivery
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                  border: _immediateDelivery
                      ? Border.all(color: Theme.of(context).primaryColor)
                      : null,
                ),
                child: Center(
                  child: Text(
                    'ส่งทันที 🛵',
                    style: TextStyle(
                      color: _immediateDelivery
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _immediateDelivery = false);
                widget.onChanged?.call(false);
              },
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: !_immediateDelivery
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                  border: !_immediateDelivery
                      ? Border.all(color: Theme.of(context).primaryColor)
                      : null,
                ),
                child: Center(
                  child: Text(
                    'รับที่ร้าน 🏪',
                    style: TextStyle(
                      color: !_immediateDelivery
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
