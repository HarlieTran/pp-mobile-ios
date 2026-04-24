import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';

/// ──────────────────────────────────────────────
/// PantryPal Mobile — Entry Point
/// Mirrors: pp-backend src/main.ts
/// ──────────────────────────────────────────────

Future<void> _configureAmplify() async {
  try {
    final authPlugin = AmplifyAuthCognito();
    await Amplify.addPlugin(authPlugin);

    final String amplifyConfig = '''{
      "UserAgent": "aws-amplify-cli/2.0",
      "Version": "1.0",
      "auth": {
        "plugins": {
          "awsCognitoAuthPlugin": {
            "UserAgent": "aws-amplify-cli/0.1.0",
            "Version": "0.1.0",
            "IdentityManager": {
              "Default": {}
            },
            "CognitoUserPool": {
              "Default": {
                "PoolId": "${dotenv.env['COGNITO_USER_POOL_ID']}",
                "AppClientId": "${dotenv.env['COGNITO_APP_CLIENT_ID']}",
                "Region": "${dotenv.env['COGNITO_REGION']}"
              }
            },
            "Auth": {
              "Default": {
                "authenticationFlowType": "USER_SRP_AUTH"
              }
            }
          }
        }
      }
    }''';

    await Amplify.configure(amplifyConfig);
    debugPrint('Successfully configured Amplify 🎉');
  } on Exception catch (e) {
    debugPrint('Error configuring Amplify: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize the API client (mirrors Express app setup)
  ApiClient.instance.init();

  // Configure Amplify Auth
  await _configureAmplify();

  runApp(const ProviderScope(child: PantryPalApp()));
}

class PantryPalApp extends ConsumerWidget {
  const PantryPalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = appRouter(ref);
    return MaterialApp.router(
      title: 'PantryPal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
