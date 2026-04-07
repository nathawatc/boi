import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_page.dart';
import '../theme/app_theme.dart';
import '../providers/settings_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  late final Animation<double> _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

  @override
  void initState() {
    super.initState();
    _controller.forward();

    // Initialize settings and navigate to HomePage after 3 seconds
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    try {
      await Future.wait([
        context.read<SettingsProvider>().initialize(),
        Future.delayed(const Duration(seconds: 3)),
      ]);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (error) {
      debugPrint('Error during splash initialization: $error');
      // Still navigate to home even if settings fail to load
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    }
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            // Responsive logo size
            final logoSize = (screenWidth * 0.45).clamp(120.0, 180.0);

            return Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Your Logo
                    Container(
                      width: logoSize,
                      height: logoSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/Logo.JPG',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    // App Name or Loading indicator
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF005699)), // Blue color
                      strokeWidth: 3,
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Text(
                      'Boi',
                      style: TextStyle(
                        fontSize: (screenWidth * 0.07).clamp(24.0, 28.0),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: const Color(0xFF005699),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
