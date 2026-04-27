import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pp_mobile/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> safePump(WidgetTester tester) async {
    try {
      await tester.pumpAndSettle(const Duration(seconds: 3));
    } catch (_) {
      // Ignore timeouts caused by infinite animations like loading spinners
      await tester.pump();
    }
  }

  testWidgets('PantryPay Showcase Journey', (WidgetTester tester) async {
    // 1. Launch the app
    app.main();
    await safePump(tester);
    
    // Allow splash/auth to resolve (give it extra time in case of network requests)
    await Future.delayed(const Duration(seconds: 10));
    await safePump(tester);

    // -- SCENE 1: DASHBOARD --
    debugPrint('🎬 SCENE 1: Dashboard');
    await Future.delayed(const Duration(seconds: 3));

    // Scroll down slowly (if scrollable exists)
    final scrollables = find.byType(Scrollable);
    if (scrollables.evaluate().isNotEmpty) {
      final scrollable = scrollables.first;
      await tester.drag(scrollable, const Offset(0, -400));
      await safePump(tester);
      await Future.delayed(const Duration(seconds: 2));

      await tester.drag(scrollable, const Offset(0, -400));
      await safePump(tester);
      await Future.delayed(const Duration(seconds: 2));
    } else {
      debugPrint('⚠️ No scrollable found, might be on a different screen. Skipping scroll.');
    }

    // -- SCENE 2: SCAN/PANTRY --
    debugPrint('🎬 SCENE 2: Navigation to Pantry');
    final pantryTab = find.byIcon(LucideIcons.package);
    if (pantryTab.evaluate().isNotEmpty) {
      await tester.tap(pantryTab.first);
      await safePump(tester);
      await Future.delayed(const Duration(seconds: 4));
    }

    // -- SCENE 3: AI CHEF / RECIPES --
    debugPrint('🎬 SCENE 3: Recipes & AI Chef');
    final recipesTab = find.byIcon(LucideIcons.bookOpen);
    if (recipesTab.evaluate().isNotEmpty) {
      await tester.tap(recipesTab.first);
      await safePump(tester);
      await Future.delayed(const Duration(seconds: 3));
      
      // Scroll recipes
      if (scrollables.evaluate().isNotEmpty) {
        await tester.drag(scrollables.first, const Offset(0, -500));
        await safePump(tester);
        await Future.delayed(const Duration(seconds: 3));
      }
    }

    // -- SCENE 4: PLANNER --
    debugPrint('🎬 SCENE 4: Planner');
    final plannerTab = find.byIcon(LucideIcons.calendarDays);
    if (plannerTab.evaluate().isNotEmpty) {
      await tester.tap(plannerTab.first);
      await safePump(tester);
      await Future.delayed(const Duration(seconds: 4));
    }

    // -- FINISH --
    // Return home
    final homeTab = find.byIcon(LucideIcons.chefHat);
    if (homeTab.evaluate().isNotEmpty) {
      await tester.tap(homeTab.first);
      await safePump(tester);
      await Future.delayed(const Duration(seconds: 3));
    }

    debugPrint('✅ Showcase Test Complete');
  });
}
