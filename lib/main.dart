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

Future<void> _configureAmplify() async {
  try {
    final authPlugin = AmplifyAuthCognito();
    await Amplify.addPlugin(authPlugin);

    final region = dotenv.env['COGNITO_REGION'] ?? '';
    final poolId = dotenv.env['COGNITO_USER_POOL_ID'] ?? '';
    final clientId = dotenv.env['COGNITO_APP_CLIENT_ID'] ?? '';

    final amplifyConfig = '''{
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
                          "PoolId": "$poolId",
                          "AppClientId": "$clientId",
                          "Region": "$region"
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
    safePrint('Successfully configured Amplify.');
  } on Exception catch (e) {
    safePrint('Error configuring Amplify: $e');
  }
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
