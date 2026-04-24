import 'dart:async';
import 'package:flutter/foundation.dart';

/// ──────────────────────────────────────────────
/// GoRouterRefreshStream
/// Thin ChangeNotifier wrapper around a Stream
/// for GoRouter.refreshListenable
/// ──────────────────────────────────────────────

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
