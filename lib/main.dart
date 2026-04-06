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

void main() {
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) {
            final robotApi = RobotApi();
            // Auto-discover robot after app starts
            WidgetsBinding.instance.addPostFrameCallback((_) {
              robotApi.autoDiscover();
            });
            return robotApi;
          }),
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
