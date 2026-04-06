// CartProvider tests require AudioPlayer platform channel initialization
// which is only available in a full widget test context.
// These tests are run via integration tests or widget tests with proper setup.
//
// To run: flutter test test/cart_provider_test.dart
// Requires: TestWidgetsFlutterBinding.ensureInitialized()

import 'package:flutter_test/flutter_test.dart';
import 'package:customer/providers/cart_provider.dart';

void main() {
  // Ensure binding is initialized for AudioPlayer
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('CartItem', () {
    test('can be created with required fields', () {
      final item = CartItem(id: '1', name: 'Test', price: '10');
      expect(item.id, '1');
      expect(item.name, 'Test');
      expect(item.price, '10');
      expect(item.quantity, 1);
    });

    test('can be created with custom quantity', () {
      final item = CartItem(id: '1', name: 'Test', price: '10', quantity: 5);
      expect(item.quantity, 5);
    });
  });

  group('Coupon', () {
    test('can be created with required fields', () {
      final coupon = Coupon(
        code: 'TEST',
        title: 'Test Coupon',
        discountAmount: 50,
        expiryDate: DateTime(2099, 12, 31),
      );
      expect(coupon.code, 'TEST');
      expect(coupon.isCollected, false);
      expect(coupon.isExpired, false);
    });

    test('detects expired coupon', () {
      final coupon = Coupon(
        code: 'EXPIRED',
        title: 'Expired',
        discountAmount: 10,
        expiryDate: DateTime(2020, 1, 1),
      );
      expect(coupon.isExpired, true);
    });

    test('formats expiry date correctly (Buddhist Era)', () {
      final coupon = Coupon(
        code: 'TEST',
        title: 'Test',
        discountAmount: 10,
        expiryDate: DateTime(2026, 6, 15),
      );
      expect(coupon.expiryDateFormatted, '15/6/2569');
    });
  });

  group('Order', () {
    test('can be created with required fields', () {
      final order = Order(
        id: '123',
        items: [],
        totalAmount: 100,
        date: DateTime.now(),
      );
      expect(order.id, '123');
      expect(order.status, 'กำลังจัดส่ง');
      expect(order.estimatedMinutes, 15);
      expect(order.discount, 0);
    });
  });
}
