import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';

/// ──────────────────────────────────────────────
/// PantryPal Mobile — Entry Point
/// Mirrors: pp-backend src/main.ts
/// ──────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize the API client (mirrors Express app setup)
  ApiClient.instance.init();

  // TODO: Configure Amplify Auth here
  // await _configureAmplify();

  runApp(const ProviderScope(child: PantryPalApp()));
}

class PantryPalApp extends StatelessWidget {
  const PantryPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PantryPal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
