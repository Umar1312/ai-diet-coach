import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// TODO: Add firebase_core and firebase_auth imports once Firebase is configured.
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/app_theme.dart';
import 'core/router/app_router.dart';
import 'stores/auth_store.dart';
import 'stores/onboarding_store.dart';
import 'stores/dashboard_store.dart';
import 'features/log_meal/stores/text_log_store.dart';

final authStore = AuthStore();
final onboardingStore = OnboardingStore();
final dashboardStore = DashboardStore();
final textLogStore = TextLogStore();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  // TODO: Initialize Firebase before runApp once firebase_options.dart is generated.
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

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

  // TODO: Check for existing Firebase user and set auth token.
  // final user = FirebaseAuth.instance.currentUser;
  // if (user != null) {
  //   final token = await user.getIdToken();
  //   authStore.setToken(token);
  // }

  // Dev-mode auth bypass: skips Firebase when a test token is configured.
  if (kDebugMode && AppConstants.devBearerToken.isNotEmpty) {
    authStore.setToken(AppConstants.devBearerToken);
  }

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
