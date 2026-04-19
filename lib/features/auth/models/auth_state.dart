// ──────────────────────────────────────────────
// Auth Models
// Mirrors: pp-backend modules/auth
// ──────────────────────────────────────────────

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? email;
  final String? errorMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.email,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? email,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      email: email ?? this.email,
      errorMessage: errorMessage,
    );
  }
}
