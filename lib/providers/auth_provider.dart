import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService, bool initializeAuth = true})
    : _authService = authService ?? AuthService() {
    if (!initializeAuth) return;

    _user = _authService.currentUser;
    if (_user != null) {
      loadProfile();
    }

    _authSubscription = _authService.authStateChanges.listen((authState) {
      _user = authState.session?.user;

      if (_user == null) {
        _profileName = null;
        _profileEmail = null;
      } else {
        loadProfile();
      }

      notifyListeners();
    });
  }

  final AuthService _authService;
  StreamSubscription<AuthState>? _authSubscription;

  bool _isLoading = false;
  String? _errorMessage;
  User? _user;
  String? _profileName;
  String? _profileEmail;
  bool _requiresEmailConfirmation = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get user => _user;
  bool get isLoggedIn => _user != null;
  String? get name => _profileName ?? _user?.userMetadata?['name']?.toString();
  String? get email => _profileEmail ?? _user?.email;
  bool get requiresEmailConfirmation => _requiresEmailConfirmation;

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return _runAuthAction(
      actionName: 'register',
      action: () async {
        final response = await _authService.register(
          name: name,
          email: email,
          password: password,
        );

        _requiresEmailConfirmation = response.session == null;
        if (_requiresEmailConfirmation) {
          _user = null;
          _profileName = name;
          _profileEmail = email;
          _errorMessage =
              'Registrasi berhasil. Silakan cek email untuk konfirmasi akun.';
          return false;
        }

        _user = response.user;
        await loadProfile();
        return _user != null;
      },
    );
  }

  Future<bool> login({required String email, required String password}) async {
    return _runAuthAction(
      actionName: 'login',
      action: () async {
        final response = await _authService.login(
          email: email,
          password: password,
        );
        _user = response.user;
        await loadProfile();
        return _user != null;
      },
    );
  }

  Future<bool> logout() async {
    return _runAuthAction(
      actionName: 'logout',
      action: () async {
        await _authService.logout();
        _user = null;
        _profileName = null;
        _profileEmail = null;
        return true;
      },
    );
  }

  Future<void> loadProfile() async {
    final userId = _user?.id;
    if (userId == null) return;

    try {
      final profile = await _authService.getProfile(userId);
      _profileName = profile?['name']?.toString();
      _profileEmail = profile?['email']?.toString() ?? _user?.email;
      notifyListeners();
    } catch (_) {
      _profileName = _user?.userMetadata?['name']?.toString();
      _profileEmail = _user?.email;
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String email,
  }) async {
    final userId = _user?.id;
    if (userId == null) {
      _errorMessage = 'User belum login.';
      notifyListeners();
      return false;
    }

    return _runAuthAction(
      actionName: 'updateProfile',
      action: () async {
        final profile = await _authService.updateProfile(
          userId: userId,
          name: name,
          email: email,
        );
        _profileName = profile['name']?.toString() ?? name;
        _profileEmail = profile['email']?.toString() ?? email;
        return true;
      },
    );
  }

  Future<bool> _runAuthAction({
    required String actionName,
    required Future<bool> Function() action,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _requiresEmailConfirmation = false;
    notifyListeners();

    try {
      return await action();
    } on AuthException catch (error) {
      debugPrint('Supabase Auth $actionName error: ${error.message}');
      _errorMessage = error.message;
      return false;
    } on PostgrestException catch (error) {
      debugPrint('Supabase Postgrest $actionName error: ${error.message}');
      _errorMessage = error.message;
      return false;
    } catch (error, stackTrace) {
      debugPrint('Supabase $actionName unexpected error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _errorMessage = error.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
