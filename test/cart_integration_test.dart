// CartProvider widget tests - require TestWidgetsFlutterBinding for AudioPlayer
import 'package:flutter_test/flutter_test.dart';
import 'package:customer/providers/cart_provider.dart';

void main() {
  group('CartProvider', () {
    testWidgets('addItem and removeItem', (tester) async {
      final cart = CartProvider();
      cart.addItem('p1', 'Coffee', '25');
      expect(cart.items.length, 1);
      expect(cart.subTotal, 25);

      cart.addItem('p1', 'Coffee', '25');
      expect(cart.items[0].quantity, 2);
      expect(cart.subTotal, 50);

      cart.removeItem('p1');
      expect(cart.items, isEmpty);
      cart.dispose();
    });

    testWidgets('collect and apply coupon', (tester) async {
      final cart = CartProvider();
      expect(cart.applyCoupon('WELCOME50'), false);

      cart.collectCoupon('WELCOME50');
      expect(cart.applyCoupon('WELCOME50'), true);
      expect(cart.appliedCoupon!.discountAmount, 50);

      cart.removeCoupon();
      expect(cart.appliedCoupon, isNull);
      cart.dispose();
    });

    testWidgets('applyCoupon is case insensitive', (tester) async {
      final cart = CartProvider();
      cart.collectCoupon('WELCOME50');
      expect(cart.applyCoupon('welcome50'), true);
      cart.dispose();
    });

    testWidgets('checkout creates order', (tester) async {
      final cart = CartProvider();
      cart.addItem('p1', 'Coffee', '25');
      cart.addItem('p2', 'Tea', '15');
      cart.checkout();

      expect(cart.orders.length, 1);
      expect(cart.orders[0].items.length, 2);
      expect(cart.orders[0].totalAmount, 40);
      expect(cart.items, isEmpty);
      cart.dispose();
    });

    testWidgets('checkout with discount', (tester) async {
      final cart = CartProvider();
      cart.addItem('p1', 'Coffee', '100');
      cart.collectCoupon('WELCOME50');
      cart.applyCoupon('WELCOME50');

      expect(cart.subTotal, 100);
      expect(cart.discountAmount, 50);
      expect(cart.totalAmount, 50);

      cart.checkout();
      expect(cart.orders[0].totalAmount, 50);
      expect(cart.orders[0].discount, 50);
      cart.dispose();
    });

    testWidgets('confirmOrderReceipt updates status', (tester) async {
      final cart = CartProvider();
      cart.addItem('p1', 'Coffee', '25');
      cart.checkout();
      final orderId = cart.orders[0].id;

      expect(cart.orders[0].status, 'กำลังจัดส่ง');
      cart.confirmOrderReceipt(orderId);
      expect(cart.orders[0].status, 'สำเร็จ');
      cart.dispose();
    });

    testWidgets('confirmOrderReceipt ignores unknown id', (tester) async {
      final cart = CartProvider();
      cart.addItem('p1', 'Coffee', '25');
      cart.checkout();

      cart.confirmOrderReceipt('nonexistent');
      expect(cart.orders[0].status, 'กำลังจัดส่ง');
      cart.dispose();
    });

    testWidgets('stopCall is safe without active call', (tester) async {
      final cart = CartProvider();
      cart.stopCall();
      expect(cart.isIncomingCall, false);
      cart.dispose();
    });

    testWidgets('dispose after operations is safe', (tester) async {
      final cart = CartProvider();
      cart.addItem('p1', 'Coffee', '25');
      cart.collectCoupon('WELCOME50');
      cart.applyCoupon('WELCOME50');
      cart.checkout();
      cart.stopCall();
      cart.dispose();
    });

    testWidgets('tab navigation', (tester) async {
      final cart = CartProvider();
      expect(cart.currentTabIndex, 0);
      cart.setTabIndex(3);
      expect(cart.currentTabIndex, 3);
      cart.dispose();
    });

    testWidgets('empty cart checkout does nothing', (tester) async {
      final cart = CartProvider();
      cart.checkout();
      expect(cart.orders, isEmpty);
      cart.dispose();
    });

    testWidgets('clearCart removes all items', (tester) async {
      final cart = CartProvider();
      cart.addItem('p1', 'A', '10');
      cart.addItem('p2', 'B', '20');
      cart.clearCart();
      expect(cart.items, isEmpty);
      cart.dispose();
    });

    testWidgets('removeItem clears coupon when empty', (tester) async {
      final cart = CartProvider();
      cart.addItem('p1', 'A', '50');
      cart.collectCoupon('WELCOME50');
      cart.applyCoupon('WELCOME50');
      expect(cart.appliedCoupon, isNotNull);

      cart.removeItem('p1');
      expect(cart.appliedCoupon, isNull);
      cart.dispose();
    });
  });
}
