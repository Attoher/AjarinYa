import 'package:flutter/material.dart';
import 'package:ajarin_ya/models/user_profile.dart';
import 'package:ajarin_ya/repositories/auth_repository.dart';
import 'dart:math' as dart_math;

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

  Future<bool> joinGroup(String groupId, {String? groupName}) async {
    _setLoading(true);
    _setErrorMessage(null);
    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      await _authRepository.joinGroup(groupId, groupName: groupName);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setErrorMessage(e.toString());
      return false;
    }
  }

  Future<bool> createGroup(String groupName) async {
    _setLoading(true);
    _setErrorMessage(null);
    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      // Generate random 6-digit code properly
      final math = dart_math.Random();
      final newGroupId = (100000 + math.nextInt(900000)).toString();
      await _authRepository.joinGroup(newGroupId, groupName: groupName);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setErrorMessage(e.toString());
      return false;
    }
  }

  Future<bool> switchActiveGroup(String groupId) async {
    _setLoading(true);
    _setErrorMessage(null);
    try {
      await _authRepository.switchActiveGroup(groupId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setErrorMessage(e.toString());
      return false;
    }
  }

  Future<void> updateAvatarUrl(String url) async {
    await _authRepository.updateAvatarUrl(url);
  }

  Future<bool> leaveGroup(String groupId) async {
    _setLoading(true);
    _setErrorMessage(null);
    try {
      await _authRepository.leaveGroup(groupId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setErrorMessage(e.toString());
      return false;
    }
  }
}
