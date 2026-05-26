import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ajarin_ya/models/user_profile.dart';

abstract class AuthRepository {
  Stream<UserProfile?> get onAuthStateChanged;
  Future<UserProfile?> loginWithEmailAndPassword(String email, String password);
  Future<UserProfile?> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  );
  Future<void> updateGroupId(
    String groupId,
  ); // keep for backward compat internally if needed
  Future<void> joinGroup(String groupId, {String? groupName});
  Future<void> leaveGroup(String groupId);
  Future<void> switchActiveGroup(String groupId);
  Future<void> signOut();
  UserProfile? get currentUser;
}

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth? _customAuth;
  final FirebaseFirestore? _customDb;
  final _authStateController = StreamController<UserProfile?>.broadcast();
  UserProfile? _currentCachedUser;
  bool _firebaseAvailable = true;

  AuthRepositoryImpl({FirebaseAuth? auth, FirebaseFirestore? db})
    : _customAuth = auth,
      _customDb = db {
    _initAuthState();
  }

  FirebaseAuth? get _auth {
    if (!_firebaseAvailable) return null;
    try {
      return _customAuth ?? FirebaseAuth.instance;
    } catch (e) {
      developer.log(
        'Firebase Auth belum diinisialisasi. Mengaktifkan otentikasi simulasi lokal.',
        name: 'AUTH_DIAGNOSTICS',
        error: e,
      );
      _firebaseAvailable = false;
      return null;
    }
  }

  FirebaseFirestore? get _db {
    if (!_firebaseAvailable) return null;
    try {
      return _customDb ?? FirebaseFirestore.instance;
    } catch (e) {
      developer.log(
        'Firebase Firestore belum diinisialisasi.',
        name: 'AUTH_DIAGNOSTICS',
        error: e,
      );
      return null;
    }
  }

  Future<UserProfile> _loadOrCreateUserProfile(
    String uid,
    String email,
    String displayName,
    String avatarUrl,
  ) async {
    final db = _db;
    if (db != null) {
      try {
        final docRef = db.collection('users').doc(uid);
        final docSnapshot = await docRef.get();
        if (docSnapshot.exists && docSnapshot.data() != null) {
          developer.log(
            'User profile found in Firestore for uid: $uid',
            name: 'AUTH_DIAGNOSTICS',
          );
          return UserProfile.fromJson(docSnapshot.data()!);
        } else {
          developer.log(
            'User profile NOT found in Firestore. Creating default for uid: $uid',
            name: 'AUTH_DIAGNOSTICS',
          );
          final newProfile = UserProfile(
            uid: uid,
            email: email,
            displayName: displayName,
            avatarUrl: avatarUrl,
            groupIds: const [],
            groupNames: const {},
            activeGroupId: null,
          );
          await docRef.set(newProfile.toJson());
          return newProfile;
        }
      } catch (e) {
        developer.log(
          'Error loading/creating profile in Firestore: $e',
          name: 'AUTH_DIAGNOSTICS',
        );
      }
    }

    // Local fallback
    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
  }

  void _initAuthState() {
    final firebaseAuth = _auth;
    if (firebaseAuth != null) {
      firebaseAuth.authStateChanges().listen((User? user) async {
        if (user != null) {
          final profile = await _loadOrCreateUserProfile(
            user.uid,
            user.email ?? '',
            user.displayName ?? 'Mahasiswa ITS',
            user.photoURL ?? '',
          );
          _currentCachedUser = profile;
          _authStateController.add(profile);
        } else {
          _currentCachedUser = null;
          _authStateController.add(null);
        }
      });
    } else {
      developer.log(
        'Firebase Auth tidak tersedia. Tidak dapat melakukan auto-login.',
        name: 'AUTH_DIAGNOSTICS',
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
          final profile = await _loadOrCreateUserProfile(
            user.uid,
            user.email ?? '',
            user.displayName ?? 'Mahasiswa ITS',
            user.photoURL ?? '',
          );
          _currentCachedUser = profile;
          _authStateController.add(profile);
          return profile;
        }
      } catch (e) {
        developer.log(
          'Firebase Auth login gagal: $e',
          name: 'AUTH_DIAGNOSTICS',
        );
        rethrow;
      }
    }
    throw Exception('Firebase Auth tidak terinisialisasi.');
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
          final profile = await _loadOrCreateUserProfile(
            user.uid,
            user.email ?? '',
            displayName,
            '',
          );
          _currentCachedUser = profile;
          _authStateController.add(profile);
          return profile;
        }
      } catch (e) {
        developer.log(
          'Firebase Auth register gagal: $e',
          name: 'AUTH_DIAGNOSTICS',
        );
        rethrow;
      }
    }
    throw Exception('Firebase Auth tidak terinisialisasi.');
  }

  @override
  Future<void> signOut() async {
    final firebaseAuth = _auth;
    if (firebaseAuth != null) {
      try {
        await firebaseAuth.signOut();
      } catch (e) {
        developer.log('Firebase signOut gagal: $e', name: 'AUTH_DIAGNOSTICS');
      }
    }
    _currentCachedUser = null;
    _authStateController.add(null);
  }

  @override
  Future<void> updateGroupId(String groupId) async {
    await joinGroup(groupId);
  }

  @override
  Future<void> joinGroup(String groupId, {String? groupName}) async {
    if (_currentCachedUser != null) {
      final currentGroups = List<String>.from(_currentCachedUser!.groupIds);
      if (!currentGroups.contains(groupId)) {
        currentGroups.add(groupId);
      }

      final currentNames = Map<String, String>.from(
        _currentCachedUser!.groupNames,
      );
      currentNames[groupId] = groupName ?? 'Grup $groupId';

      final updatedProfile = UserProfile(
        uid: _currentCachedUser!.uid,
        email: _currentCachedUser!.email,
        displayName: _currentCachedUser!.displayName,
        avatarUrl: _currentCachedUser!.avatarUrl,
        groupIds: currentGroups,
        groupNames: currentNames,
        activeGroupId: groupId,
      );

      final db = _db;
      if (db != null) {
        try {
          // Sync with groups collection
          final groupDoc = await db.collection('groups').doc(groupId).get();
          if (!groupDoc.exists) {
            await db.collection('groups').doc(groupId).set({
              'name': groupName ?? 'Grup $groupId',
              'leaderId': updatedProfile.uid,
              'memberIds': [updatedProfile.uid],
            });
          } else {
            await db.collection('groups').doc(groupId).update({
              'memberIds': FieldValue.arrayUnion([updatedProfile.uid]),
            });
            final data = groupDoc.data()!;
            if (data.containsKey('name')) {
              updatedProfile.groupNames[groupId] = data['name'];
            }
          }

          await db
              .collection('users')
              .doc(updatedProfile.uid)
              .set(updatedProfile.toJson());
          developer.log(
            'Persisted user profile to Firestore for joinGroup',
            name: 'AUTH_DIAGNOSTICS',
          );
        } catch (e) {
          developer.log(
            'Failed to persist user profile: $e',
            name: 'AUTH_DIAGNOSTICS',
          );
        }
      }

      _currentCachedUser = updatedProfile;
      _authStateController.add(updatedProfile);
    }
  }

  @override
  Future<void> leaveGroup(String groupId) async {
    if (_currentCachedUser != null) {
      final currentGroups = List<String>.from(_currentCachedUser!.groupIds);
      currentGroups.remove(groupId);

      final currentNames = Map<String, String>.from(
        _currentCachedUser!.groupNames,
      );
      currentNames.remove(groupId);

      String? newActiveId = _currentCachedUser!.activeGroupId;
      if (newActiveId == groupId) {
        newActiveId = currentGroups.isNotEmpty ? currentGroups.first : null;
      }

      final updatedProfile = UserProfile(
        uid: _currentCachedUser!.uid,
        email: _currentCachedUser!.email,
        displayName: _currentCachedUser!.displayName,
        avatarUrl: _currentCachedUser!.avatarUrl,
        groupIds: currentGroups,
        groupNames: currentNames,
        activeGroupId: newActiveId,
      );

      final db = _db;
      if (db != null) {
        try {
          // Remove user from groups collection
          await db.collection('groups').doc(groupId).update({
            'memberIds': FieldValue.arrayRemove([updatedProfile.uid]),
          });

          await db
              .collection('users')
              .doc(updatedProfile.uid)
              .set(updatedProfile.toJson());
          developer.log(
            'Persisted user profile to Firestore for leaveGroup',
            name: 'AUTH_DIAGNOSTICS',
          );
        } catch (e) {
          developer.log(
            'Failed to persist user profile: $e',
            name: 'AUTH_DIAGNOSTICS',
          );
        }
      }

      _currentCachedUser = updatedProfile;
      _authStateController.add(updatedProfile);
    }
  }

  @override
  Future<void> switchActiveGroup(String groupId) async {
    if (_currentCachedUser != null) {
      if (_currentCachedUser!.groupIds.contains(groupId)) {
        final updatedProfile = UserProfile(
          uid: _currentCachedUser!.uid,
          email: _currentCachedUser!.email,
          displayName: _currentCachedUser!.displayName,
          avatarUrl: _currentCachedUser!.avatarUrl,
          groupIds: _currentCachedUser!.groupIds,
          groupNames: _currentCachedUser!.groupNames,
          activeGroupId: groupId,
        );

        final db = _db;
        if (db != null) {
          try {
            await db
                .collection('users')
                .doc(updatedProfile.uid)
                .set(updatedProfile.toJson());
            developer.log(
              'Persisted user profile to Firestore for switchActiveGroup',
              name: 'AUTH_DIAGNOSTICS',
            );
          } catch (e) {
            developer.log(
              'Failed to persist user profile: $e',
              name: 'AUTH_DIAGNOSTICS',
            );
          }
        }

        _currentCachedUser = updatedProfile;
        _authStateController.add(updatedProfile);
      }
    }
  }
}
