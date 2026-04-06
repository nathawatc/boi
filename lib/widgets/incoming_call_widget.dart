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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final screenWidth = constraints.maxWidth;
            // Make ripple container responsive - 35% of screen height for better centering
            final rippleSize = (screenHeight * 0.35).clamp(180.0, 280.0);
            final logoSize = (rippleSize * 0.78).clamp(140.0, 220.0);

            return Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: screenHeight,
                    maxWidth: screenWidth * 0.9, // Prevent edge overflow
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      // Header Section
                      Text(
                        'Boi มาถึงแล้ว',
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontSize: screenWidth < 360 ? 22 : 26,
                          fontWeight: FontWeight.bold
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'กรุณารับสินค้าและกดยืนยัน',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: screenWidth < 360 ? 14 : 16,
                            fontWeight: FontWeight.w500
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.04),

                      // Responsive Ripple Container
                      SizedBox(
                        height: rippleSize,
                        width: rippleSize,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _buildRipple(scale: 1.0, opacity: 0.15, baseSize: rippleSize * 0.625),
                            _buildRipple(scale: 1.4, opacity: 0.1, baseSize: rippleSize * 0.625),
                            _buildRipple(scale: 1.8, opacity: 0.05, baseSize: rippleSize * 0.625),

                            // Enlarge Rounded Logo Container
                            Container(
                              width: logoSize,
                              height: logoSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.surface,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryGreen.withOpacity(0.15),
                                    blurRadius: 35,
                                    spreadRadius: 5
                                  ),
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.shadow.withOpacity(0.15),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5)
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/Logo.JPG',
                                  width: logoSize,
                                  height: logoSize,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.04),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Text(
                          'กรุณารับสินค้าภายในเวลาที่กำหนด',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Consumer<CartProvider>(
                        builder: (context, cart, child) {
                          final minutes = (cart.callTimeoutSeconds ~/ 60).toString().padLeft(2, '0');
                          final seconds = (cart.callTimeoutSeconds % 60).toString().padLeft(2, '0');
                          return Column(
                            children: [
                              Text(
                                'เวลารับสินค้าที่เหลือ:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$minutes:$seconds',
                                style: TextStyle(
                                  fontSize: screenWidth < 360 ? 28 : 32,
                                  fontWeight: FontWeight.bold,
                                  color: cart.callTimeoutSeconds <= 30 ? Colors.red : AppTheme.primaryGreen
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          );
                        },
                      ),

                      SizedBox(height: screenHeight * 0.03),

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
                            Text(
                              'ปิด',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRipple({required double scale, required double opacity, required double baseSize}) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = (_controller.value + (scale - 1.0) / 0.8) % 1.0;
        final currentScale = 1.0 + (progress * 0.8);
        final currentOpacity = (1.0 - progress) * opacity;

        return Container(
          width: baseSize * currentScale,
          height: baseSize * currentScale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryGreen.withOpacity(currentOpacity),
          ),
        );
      },
    );
  }
}
