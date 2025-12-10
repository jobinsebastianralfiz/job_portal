import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/route_constants.dart';
import 'routes/app_router.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/job_provider.dart';
import 'providers/application_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/ai_provider.dart';
import 'providers/subscription_provider.dart';

// Global keys for accessing scaffold messenger without context
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Authentication Provider
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // Job Provider - manages job listings and searches
        ChangeNotifierProvider(create: (_) => JobProvider()),

        // Application Provider - manages job applications
        ChangeNotifierProvider(create: (_) => ApplicationProvider()),

        // Admin Provider - admin dashboard and management
        ChangeNotifierProvider(create: (_) => AdminProvider()),

        // AI Provider - resume parsing and AI features
        ChangeNotifierProvider(create: (_) => AIProvider()),

        // Subscription Provider - manages subscriptions and payments
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ],
      child: MaterialApp(
        title: 'JobPortal',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: scaffoldMessengerKey,
        navigatorKey: navigatorKey,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        initialRoute: RouteConstants.splash,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
