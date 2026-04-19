import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

/// ──────────────────────────────────────────────
/// Auth Service
/// Mirrors: pp-backend modules/auth
/// Wraps AWS Amplify Cognito SDK for sign-in/up/out
/// ──────────────────────────────────────────────

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  /// Get the current Cognito id_token for API calls
  Future<String?> getIdToken() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (session is CognitoAuthSession) {
        return session.userPoolTokensResult.value.idToken.raw;
      }
    } catch (_) {}
    return null;
  }

  /// Sign in with email + password
  Future<SignInResult> signIn({
    required String email,
    required String password,
  }) async {
    return Amplify.Auth.signIn(
      username: email,
      password: password,
    );
  }

  /// Sign up with email + password
  Future<SignUpResult> signUp({
    required String email,
    required String password,
  }) async {
    return Amplify.Auth.signUp(
      username: email,
      password: password,
      options: SignUpOptions(
        userAttributes: {CognitoUserAttributeKey.email: email},
      ),
    );
  }

  /// Confirm sign up with verification code
  Future<SignUpResult> confirmSignUp({
    required String email,
    required String code,
  }) async {
    return Amplify.Auth.confirmSignUp(
      username: email,
      confirmationCode: code,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await Amplify.Auth.signOut();
  }

  /// Check if user is currently signed in
  Future<bool> isSignedIn() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      return session.isSignedIn;
    } catch (_) {
      return false;
    }
  }

  /// Get current user attributes
  Future<List<AuthUserAttribute>> getUserAttributes() async {
    return Amplify.Auth.fetchUserAttributes();
  }
}
