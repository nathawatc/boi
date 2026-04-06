import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';

class IncomingCallWidget extends StatefulWidget {
  const IncomingCallWidget({super.key});

  @override
  State<IncomingCallWidget> createState() => _IncomingCallWidgetState();
}

class _IncomingCallWidgetState extends State<IncomingCallWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Header Section
            Text(
              'Boi มาถึงแล้ว',
              style: TextStyle(color: AppTheme.primaryGreen, fontSize: 26, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'กรุณารับสินค้าและกดยืนยัน',
              style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Fixed Size Container for Ripple
            SizedBox(
              height: 320,
              width: 320,
              child: Stack(
                alignment: Alignment.center,
                children: [
                   // Ripples
                  _buildRipple(scale: 1.0, opacity: 0.15),
                  _buildRipple(scale: 1.4, opacity: 0.1),
                  _buildRipple(scale: 1.8, opacity: 0.05),

                  // Enlarge Rounded Logo Container
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.15),
                          blurRadius: 35,
                          spreadRadius: 5
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5)
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/Logo.JPG',
                        width: 250,
                        height: 250,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            const Text(
              'กรุณารับสินค้าภายในเวลาที่กำหนด',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            Consumer<CartProvider>(
              builder: (context, cart, child) {
                final minutes = (cart.callTimeoutSeconds ~/ 60).toString().padLeft(2, '0');
                final seconds = (cart.callTimeoutSeconds % 60).toString().padLeft(2, '0');
                return Column(
                  children: [
                    const Text(
                      'เวลารับสินค้าที่เหลือ:',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$minutes:$seconds',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: cart.callTimeoutSeconds <= 30 ? Colors.red : AppTheme.primaryGreen
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 30),

            GestureDetector(
              onTap: () {
                context.read<CartProvider>().stopCall();
                context.read<CartProvider>().setTabIndex(1);
              },
              child: Column(
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 12),
                  const Text('ปิด', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRipple({required double scale, required double opacity}) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = (_controller.value + (scale - 1.0) / 0.8) % 1.0;
        final currentScale = 1.0 + (progress * 0.8);
        final currentOpacity = (1.0 - progress) * opacity;

        return Container(
          width: 200 * currentScale,
          height: 200 * currentScale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryGreen.withOpacity(currentOpacity),
          ),
        );
      },
    );
  }
}
