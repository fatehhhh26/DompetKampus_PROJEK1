import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/saving_goal_provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/splash_screen.dart';

class DompetKampusApp extends StatelessWidget {
  const DompetKampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => SavingGoalProvider()),
      ],
      child: MaterialApp(
        title: 'DompetKampus',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
