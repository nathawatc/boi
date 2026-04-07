import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'pages/splash_screen.dart';
import 'providers/cart_provider.dart';
import 'providers/settings_provider.dart';
import 'services/robot_api.dart';
import 'widgets/incoming_call_widget.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize RobotApi before app starts
  final robotApi = RobotApi();
  try {
    await robotApi.initialize();
    debugPrint('[main] RobotApi initialized successfully');
    // Auto-discover robot
    robotApi.autoDiscover();
  } catch (e) {
    debugPrint('[main] RobotApi initialization failed: $e');
  }

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider.value(value: robotApi),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: const BoiApp(),
      ),
    ),
  );
}

class BoiApp extends StatelessWidget {
  const BoiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          locale: DevicePreview.locale(context),
          title: 'Boi',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.materialThemeMode,
          home: const SplashScreen(),
          builder: (context, child) {
            // Apply DevicePreview.appBuilder as base
            final previewChild = DevicePreview.appBuilder(context, child);

            return Stack(
              children: [
                previewChild,
                Consumer<CartProvider>(
                  builder: (context, cart, _) {
                    if (cart.isIncomingCall) {
                      return const Positioned.fill(
                        child: IncomingCallWidget(),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
