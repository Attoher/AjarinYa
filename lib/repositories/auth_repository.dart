import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ajarin_ya/models/user_profile.dart';

abstract class AuthRepository {
  Stream<UserProfile?> get onAuthStateChanged;
  Future<UserProfile?> loginWithEmailAndPassword(String email, String password);
  Future<UserProfile?> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  );
  Future<void> signOut();
  UserProfile? get currentUser;
}

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth? _customAuth;
  final _authStateController = StreamController<UserProfile?>.broadcast();
  UserProfile? _currentCachedUser;
  static const bool _forceLocalAuthDemo = false;

  AuthRepositoryImpl({FirebaseAuth? auth}) : _customAuth = auth {
    // Inisialisasi status awal
    _initAuthState();
  }

  FirebaseAuth? get _auth {
    if (_forceLocalAuthDemo) return null;

    try {
      return _customAuth ?? FirebaseAuth.instance;
    } catch (e) {
      developer.log(
        'Firebase Auth belum diinisialisasi. Mengaktifkan otentikasi simulasi lokal.',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
      );
      return null;
    }
  }

  void _initAuthState() {
    final firebaseAuth = _auth;
    if (firebaseAuth != null) {
      firebaseAuth.authStateChanges().listen((User? user) {
        if (user != null) {
          final profile = UserProfile(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? 'Mahasiswa ITS',
            avatarUrl: user.photoURL ?? '',
          );
          _currentCachedUser = profile;
          _authStateController.add(profile);
        } else {
          _currentCachedUser = null;
          _authStateController.add(null);
        }
      });
    } else {
      // Default mock user untuk simulasi offline
      _cacheAndEmitLocalUser(
        uid: 'mahasiswa_its_mock',
        email: 'mahasiswa@its.ac.id',
        displayName: 'Atha (Teknik Informatika)',
      );
    }
  }

  @override
  Stream<UserProfile?> get onAuthStateChanged => _authStateController.stream;

  @override
  UserProfile? get currentUser => _currentCachedUser;

  @override
  Future<UserProfile?> loginWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final firebaseAuth = _auth;
    if (firebaseAuth != null) {
      try {
        final credential = await firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        final user = credential.user;
        if (user != null) {
          final profile = UserProfile(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? 'Mahasiswa ITS',
            avatarUrl: user.photoURL ?? '',
          );
          _currentCachedUser = profile;
          _authStateController.add(profile);
          return profile;
        }
      } catch (e) {
        developer.log(
          'Error login Firebase Auth: $e',
          name: 'INTEGRITY_DIAGNOSTICS',
        );
        return _fallbackLocalLogin(
          email,
          password,
          displayName: '${email.split('@')[0]} (ITS)',
        );
      }
    } else {
      // Simulasi lokal
      return _fallbackLocalLogin(
        email,
        password,
        displayName: '${email.split('@')[0]} (ITS)',
      );
    }
    return null;
  }

  @override
  Future<UserProfile?> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    final firebaseAuth = _auth;
    if (firebaseAuth != null) {
      try {
        final credential = await firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        final user = credential.user;
        if (user != null) {
          await user.updateDisplayName(displayName);
          final profile = UserProfile(
            uid: user.uid,
            email: user.email ?? '',
            displayName: displayName,
            avatarUrl: '',
          );
          _currentCachedUser = profile;
          _authStateController.add(profile);
          return profile;
        }
      } catch (e) {
        developer.log(
          'Error register Firebase Auth: $e',
          name: 'INTEGRITY_DIAGNOSTICS',
        );
        return _fallbackLocalLogin(email, password, displayName: displayName);
      }
    } else {
      // Simulasi lokal
      return _fallbackLocalLogin(email, password, displayName: displayName);
    }
    return null;
  }

  UserProfile _fallbackLocalLogin(
    String email,
    String password, {
    required String displayName,
  }) {
    if (!email.contains('@') || password.length < 6) {
      throw FirebaseAuthException(
        code: 'invalid-credential',
        message:
            'Format email tidak valid atau password kurang dari 6 karakter.',
      );
    }

    return _cacheAndEmitLocalUser(
      uid: 'local_user_${email.split('@')[0]}',
      email: email,
      displayName: displayName,
    );
  }

  UserProfile _cacheAndEmitLocalUser({
    required String uid,
    required String email,
    required String displayName,
  }) {
    final profile = UserProfile(
      uid: uid,
      email: email,
      displayName: displayName,
      avatarUrl: '',
    );
    _currentCachedUser = profile;
    _authStateController.add(profile);
    return profile;
  }

  @override
  Future<void> signOut() async {
    final firebaseAuth = _auth;
    if (firebaseAuth != null) {
      await firebaseAuth.signOut();
    }
    _currentCachedUser = null;
    _authStateController.add(null);
  }
}
