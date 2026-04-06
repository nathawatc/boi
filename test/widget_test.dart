// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:customer/providers/cart_provider.dart';

void main() {
  testWidgets('CartProvider can be created and disposed', (WidgetTester tester) async {
    // Test that CartProvider can be instantiated and disposed properly
    final cartProvider = CartProvider();
    expect(cartProvider, isNotNull);
    expect(cartProvider.items, isEmpty);
    expect(cartProvider.orders, isEmpty);

    // Dispose to clean up timers
    cartProvider.dispose();
  });
}
