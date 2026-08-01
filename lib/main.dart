import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:our_space/services/auth_service.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_state.dart';
import 'services/notification_service.dart';
import 'core/widgets/cute_widgets.dart';
import 'features/home/presentation/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final appState = AppState();

  // Kick off sign-in + data loading in the background — do NOT await
  // these before runApp(). A slow/offline connection must never block
  // the first frame from drawing.
  unawaited(_bootstrap(appState));

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const OurSpaceApp(),
    ),
  );
}

Future<void> _bootstrap(AppState appState) async {
  try {
    await AuthService.signInAnonymously();
  } catch (e, s) {
    debugPrint('Anonymous sign-in failed: $e');
    debugPrintStack(stackTrace: s);
  }

  await appState.init();

  unawaited(
    NotificationService.instance.init().catchError(
      (Object error, StackTrace stack) {
        debugPrint('Notification initialization failed: $error');
        debugPrintStack(stackTrace: stack);
      },
    ),
  );
}

class OurSpaceApp extends StatelessWidget {
  const OurSpaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return MaterialApp(
      title: 'Twilights Together',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.forTwilight(state.twilight),
      home: DreamyBackground(
        isDay: state.isDay,
        child: state.isInitializing ? const _LoadingScreen() : const HomeScreen(),
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('💗', style: TextStyle(fontSize: 40)),
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}