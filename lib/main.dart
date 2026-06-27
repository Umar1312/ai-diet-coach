import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/app_theme.dart';
import 'core/router/app_router.dart';
import 'stores/auth_store.dart';
import 'stores/onboarding_store.dart';
import 'stores/dashboard_store.dart';
import 'stores/pantry_suggestions_store.dart';
import 'features/log_meal/stores/text_log_store.dart';
import 'features/craving/stores/craving_store.dart';
import 'features/pantry/stores/pantry_store.dart';
import 'features/customize_day/stores/customize_day_store.dart';

final authStore = AuthStore();
final onboardingStore = OnboardingStore();
final dashboardStore = DashboardStore();
final pantryStore = PantryStore(dashboardStore: dashboardStore);
final textLogStore = TextLogStore();
final pantrySuggestionsStore = PantrySuggestionsStore(pantryStore: pantryStore);
final cravingStore = CravingStore();
final customizeDayStore = CustomizeDayStore();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  final useDevAuth = kDebugMode && AppConstants.devBearerToken.isNotEmpty;

  if (useDevAuth) {
    await authStore.setDevToken(AppConstants.devBearerToken);
  } else {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      authStore.init();
    } catch (e) {
      debugPrint('Firebase init failed: $e');
      authStore.markUnauthenticated();
    }
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AI Diet Buddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
