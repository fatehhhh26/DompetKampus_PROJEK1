import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _name;

  bool get isLoggedIn => _isLoggedIn;
  String? get name => _name;

  void login({required String name}) {
    _name = name;
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _name = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
