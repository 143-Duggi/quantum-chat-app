import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/inactivity_provider.dart';
import 'router/app_router.dart';
import 'firebase_options.dart';
import 'screens/auto_lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const QuantumChatApp());
}

class QuantumChatApp extends StatefulWidget {
  const QuantumChatApp({super.key});

  @override
  State<QuantumChatApp> createState() => _QuantumChatAppState();
}

class _QuantumChatAppState extends State<QuantumChatApp> {
  late InactivityProvider _inactivityProvider;

  @override
  void initState() {
    super.initState();
    _inactivityProvider = InactivityProvider();
    _inactivityProvider.initialize();
  }

  @override
  void dispose() {
    _inactivityProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: _inactivityProvider),
      ],
      child: Consumer2<ThemeProvider, InactivityProvider>(
        builder: (context, themeProvider, inactivityProvider, child) {
          // Show lock screen if app is locked
          if (inactivityProvider.isLocked) {
            return MaterialApp(
              title: 'QuantumChat',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              home: const AutoLockScreen(),
            );
          }

          // Wrap with GestureDetector to track user activity
          return GestureDetector(
            onTap: () => inactivityProvider.recordActivity(),
            onPanDown: (_) => inactivityProvider.recordActivity(),
            onScaleStart: (_) => inactivityProvider.recordActivity(),
            behavior: HitTestBehavior.translucent,
            child: MaterialApp.router(
              title: 'QuantumChat',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              routerConfig: AppRouter.router,
            ),
          );
        },
      ),
    );
  }
}
