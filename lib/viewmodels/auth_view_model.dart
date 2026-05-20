import 'package:flutter/material.dart';
import 'package:ajarin_ya/models/user_profile.dart';
import 'package:ajarin_ya/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  UserProfile? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AuthViewModel({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepositoryImpl() {
    _authRepository.onAuthStateChanged.listen((UserProfile? user) {
      _user = user;
      notifyListeners();
    });
    // Inisialisasi awal
    _user = _authRepository.currentUser;
  }

  UserProfile? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _setErrorMessage(String? msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setErrorMessage(null);
    try {
      final loggedInUser = await _authRepository.loginWithEmailAndPassword(email, password);
      _setLoading(false);
      return loggedInUser != null;
    } catch (e) {
      _setLoading(false);
      _setErrorMessage(e.toString().split('] ').last);
      return false;
    }
  }

  Future<bool> register(String email, String password, String displayName) async {
    _setLoading(true);
    _setErrorMessage(null);
    try {
      final registeredUser = await _authRepository.registerWithEmailAndPassword(
        email,
        password,
        displayName,
      );
      _setLoading(false);
      return registeredUser != null;
    } catch (e) {
      _setLoading(false);
      _setErrorMessage(e.toString().split('] ').last);
      return false;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    await _authRepository.signOut();
    _setLoading(false);
  }
}
