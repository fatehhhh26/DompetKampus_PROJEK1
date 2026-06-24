import 'package:dompet_kampus/providers/auth_provider.dart';
import 'package:dompet_kampus/screens/login_screen.dart';
import 'package:dompet_kampus/screens/register_screen.dart';
import 'package:dompet_kampus/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget _buildTestApp(Widget child) {
  return ChangeNotifierProvider<AuthProvider>(
    create: (_) => AuthProvider(initializeAuth: false),
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('DompetKampus shows splash screen', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(const SplashScreen(autoNavigate: false)),
    );

    expect(find.text('DompetKampus'), findsOneWidget);
    expect(find.text('Catatan keuangan mahasiswa'), findsOneWidget);
  });

  testWidgets('LoginScreen shows email, password, and login button', (
    tester,
  ) async {
    await tester.pumpWidget(_buildTestApp(const LoginScreen()));

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Masuk'), findsWidgets);
  });

  testWidgets(
    'RegisterScreen shows name, email, password, and register button',
    (tester) async {
      await tester.pumpWidget(_buildTestApp(const RegisterScreen()));

      expect(find.text('Nama lengkap'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Daftar'), findsWidgets);
    },
  );
}
