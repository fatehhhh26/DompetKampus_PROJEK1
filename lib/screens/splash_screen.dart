import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/saving_goal_provider.dart';
import '../providers/transaction_provider.dart';
import 'login_screen.dart';
import 'main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.autoNavigate = true});

  final bool autoNavigate;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.autoNavigate) {
      _openNextScreen();
    }
  }

  Future<void> _openNextScreen() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final isLoggedIn = context.read<AuthProvider>().isLoggedIn;
    if (isLoggedIn) {
      unawaited(_loadInitialData());
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            isLoggedIn ? const MainNavigationScreen() : const LoginScreen(),
      ),
    );
  }

  Future<void> _loadInitialData() async {
    try {
      await Future.wait([
        context.read<TransactionProvider>().loadTransactions(),
        context.read<SavingGoalProvider>().loadSavingGoals(),
        context.read<BudgetProvider>().loadBudgets(),
      ]);
    } catch (_) {
      // Providers already keep friendly error messages for the visible screens.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', width: 96, height: 96),
            const SizedBox(height: 16),
            const Text(
              'DompetKampus',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Catatan keuangan mahasiswa'),
          ],
        ),
      ),
    );
  }
}
