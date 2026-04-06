import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class CartItem {
  final String id;
  final String name;
  final String price;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
  });
}

class Coupon {
  final String code;
  final String title;
  final double discountAmount;
  final double minSpend;
  final DateTime expiryDate;
  bool isCollected;

  Coupon({
    required this.code,
    required this.title,
    required this.discountAmount,
    this.minSpend = 0,
    required this.expiryDate,
    this.isCollected = false,
  });

  bool get isExpired => DateTime.now().isAfter(expiryDate);

  String get expiryDateFormatted => '${expiryDate.day}/${expiryDate.month}/${expiryDate.year + 543}';
}

class Order {
  final String id;
  final List<CartItem> items;
  final double totalAmount;
  final double discount;
  final String? couponCode;
  final DateTime date;
  String status;
  int estimatedMinutes;

  Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.date,
    this.discount = 0,
    this.couponCode,
    this.status = 'กำลังจัดส่ง',
    this.estimatedMinutes = 15,
  });
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  final List<Order> _orders = [];
  Timer? _timer;
  bool _disposed = false;

  // Coupons
  final List<Coupon> _availableCoupons = [
    Coupon(code: 'WELCOME50', title: 'ส่วนลดลูกค้าใหม่ 50.-', discountAmount: 50.0, minSpend: 0, expiryDate: DateTime(2026, 12, 31)),
    Coupon(code: 'SAVE10', title: 'ส่วนลดท้ายบิล 10.-', discountAmount: 10.0, minSpend: 0, expiryDate: DateTime(2026, 12, 31)),
    Coupon(code: 'MEMBER20', title: 'ส่วนลดสมาชิก 20.-', discountAmount: 20.0, minSpend: 0, expiryDate: DateTime(2026, 12, 31)),
    Coupon(code: 'COUPON30', title: 'ส่วนลดพิเศษ 30.-', discountAmount: 30.0, minSpend: 0, expiryDate: DateTime(2026, 12, 31)),
  ];

  Coupon? _appliedCoupon;
  Coupon? get appliedCoupon => _appliedCoupon;
  List<Coupon> get availableCoupons => _availableCoupons;
  List<Coupon> get collectedCoupons => _availableCoupons.where((c) => c.isCollected).toList();

  CartProvider() {
    // Countdown timer: fires every 60 seconds (1 real minute per estimated minute)
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      // Check if there are any active orders
      final hasActiveOrders = _orders.any((o) => o.status == 'กำลังจัดส่ง' && o.estimatedMinutes > 1);

      // Only process if there are active orders
      if (!hasActiveOrders) {
        return;
      }

      bool changed = false;
      for (var order in _orders) {
        if (order.status == 'กำลังจัดส่ง' && order.estimatedMinutes > 1) {
          order.estimatedMinutes--;
          changed = true;
        }
      }
      if (changed) _safeNotifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _callTimer?.cancel();
    _pendingCallTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_disposed) notifyListeners();
  }

  List<CartItem> get items => [..._items];
  List<Order> get orders => [..._orders];
  int _currentTabIndex = 0;
  bool _isIncomingCall = false;
  bool get isIncomingCall => _isIncomingCall;
  int get currentTabIndex => _currentTabIndex;

  void setTabIndex(int index) {
    _currentTabIndex = index;
    _safeNotifyListeners();
  }

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  final AudioPlayer _audioPlayer = AudioPlayer();

  int _callTimeoutSeconds = 10;
  int get callTimeoutSeconds => _callTimeoutSeconds;
  Timer? _callTimer;
  Timer? _pendingCallTimer; // Tracks the delayed future before incoming call starts

  void playNotificationSound({bool isLong = false}) async {
    try {
      if (isLong) {
        // Reset timeout to 3 minutes (180 seconds)
        _callTimeoutSeconds = 180;

        // Cancel any pending call that was already scheduled
        _pendingCallTimer?.cancel();

        // Wait 10 seconds after checkout before simulate the "Incoming Call"
        _pendingCallTimer = Timer(const Duration(seconds: 10), () async {
          // Check if we've been disposed or the call was cancelled
          if (_disposed) return;

          _isIncomingCall = true;
          _callTimeoutSeconds = 180; // 3 minutes to receive the call
          _safeNotifyListeners();

          // 1. Start countdown timer FIRST so UI responds immediately
          _callTimer?.cancel();
          _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (_callTimeoutSeconds > 0) {
              _callTimeoutSeconds--;
              _safeNotifyListeners();
            } else {
              _handleCallTimeout();
              timer.cancel();
            }
          });

          // 2. Play sound in a try-catch so it doesn't block the timer if it fails
          try {
            await _audioPlayer.setReleaseMode(ReleaseMode.loop);
            await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
          } catch (e) {
            debugPrint('Error playing sound on mobile: $e');
          }
        });
      }
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  void _handleCallTimeout() {
    if (_isIncomingCall) {
      // Mark the latest order as failed/incomplete
      if (_orders.isNotEmpty && _orders.first.status == 'กำลังจัดส่ง') {
        _orders.first.status = 'คำสั่งซื้อไม่สำเร็จ';
      }
      stopCall();
    }
  }

  void stopCall() {
    _isIncomingCall = false;
    _callTimer?.cancel();
    _pendingCallTimer?.cancel();
    _audioPlayer.stop();
    _safeNotifyListeners();
  }

  double get subTotal {
    double total = 0.0;
    for (var item in _items) {
      double priceValue = double.tryParse(item.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
      total += priceValue * item.quantity;
    }
    return total;
  }

  double get totalAmount {
    double total = subTotal;
    if (_appliedCoupon != null && total >= _appliedCoupon!.minSpend) {
      total -= _appliedCoupon!.discountAmount;
    }
    return total < 0 ? 0 : total;
  }

  double get discountAmount {
    if (_appliedCoupon != null && subTotal >= _appliedCoupon!.minSpend) {
      return _appliedCoupon!.discountAmount;
    }
    return 0;
  }

  void collectCoupon(String code) {
    final index = _availableCoupons.indexWhere((c) => c.code == code);
    if (index >= 0) {
      _availableCoupons[index].isCollected = true;
      _safeNotifyListeners();
    }
  }

  bool applyCoupon(String code) {
    final index = _availableCoupons.indexWhere(
      (c) => c.code.toUpperCase() == code.toUpperCase() && c.isCollected && !c.isExpired,
    );

    if (index >= 0) {
      _appliedCoupon = _availableCoupons[index];
      _safeNotifyListeners();
      return true;
    }
    return false;
  }

  void removeCoupon() {
    _appliedCoupon = null;
    _safeNotifyListeners();
  }

  void addItem(String id, String name, String price, {int quantity = 1}) {
    int index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(id: id, name: name, price: price, quantity: quantity));
    }
    _safeNotifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    if (_items.isEmpty) _appliedCoupon = null;
    _safeNotifyListeners();
  }

  void checkout() {
    if (_items.isEmpty) return;

    _orders.insert(0, Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      items: List.from(_items),
      totalAmount: totalAmount,
      date: DateTime.now(),
      discount: discountAmount,
      couponCode: _appliedCoupon?.code,
    ));

    _items.clear();
    _appliedCoupon = null;
    // playNotificationSound already calls notifyListeners internally
    playNotificationSound(isLong: true);
  }

  void confirmOrderReceipt(String orderId) {
    int index = _orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      _orders[index].status = 'สำเร็จ';
      _safeNotifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _safeNotifyListeners();
  }
}
