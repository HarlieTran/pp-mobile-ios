import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/network/api_client.dart';
import '../models/auth_state.dart';

/// ──────────────────────────────────────────────
/// Auth Provider
/// Mirrors: pp-backend modules/auth + POST /me/bootstrap
/// ──────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await AuthService.instance.signIn(email: email, password: password);
      // Bootstrap user profile on backend
      await ApiClient.instance.dio.post('/me/bootstrap');
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        email: email,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _cleanErrorMessage(e),
      );
    }
  }

  Future<void> signUp(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await AuthService.instance.signUp(email: email, password: password);
      state = state.copyWith(isLoading: false, email: email);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _cleanErrorMessage(e),
      );
    }
  }

  Future<void> confirmSignUp(String email, String code) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await AuthService.instance.confirmSignUp(email: email, code: code);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _cleanErrorMessage(e),
      );
    }
  }

  Future<void> signOut() async {
    await AuthService.instance.signOut();
    state = const AuthState();
  }

  Future<void> checkAuthStatus() async {
    final signedIn = await AuthService.instance.isSignedIn();
    state = state.copyWith(isAuthenticated: signedIn);
  }

  String _cleanErrorMessage(Object e) {
    final str = e.toString();
    if (str.contains('Missing required parameter USERNAME') || 
        str.contains('Missing required parameter PASSWORD')) {
      return 'Please enter your email and password.';
    }
    if (str.contains('UserNotFoundException')) {
      return 'No account found with this email.';
    }
    if (str.contains('NotAuthorizedException')) {
      return 'Incorrect email or password.';
    }
    if (str.contains('InvalidPasswordException')) {
      return 'Password must be at least 8 characters.';
    }
    if (str.contains('UsernameExistsException')) {
      return 'An account with this email already exists.';
    }
    // Attempt to extract the "message" from AWS Cognito exceptions
    final match = RegExp(r'"message":\s*"([^"]+)"').firstMatch(str);
    if (match != null) {
      return match.group(1) ?? str;
    }
    // Fallback: remove the Exception prefix if present
    return str.replaceAll(RegExp(r'^[a-zA-Z]+Exception \{\s*'), '').replaceAll(RegExp(r'\s*\}$'), '');
  }
}
