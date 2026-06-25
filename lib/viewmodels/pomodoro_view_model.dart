import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:ajarin_ya/models/pomodoro_preset.dart';
import 'package:ajarin_ya/models/pomodoro_session.dart';
import 'package:ajarin_ya/models/result_state.dart';
import 'package:ajarin_ya/repositories/pomodoro_repository.dart';

class PomodoroViewModel extends ChangeNotifier {
  final PomodoroRepository _repository;

  PomodoroViewModel({PomodoroRepository? repository})
      : _repository = repository ?? PomodoroRepositoryImpl() {
    loadPresets();
    loadSessions();
  }

  List<PomodoroPreset> _presets = [];
  ResultState<List<PomodoroPreset>> _state = const ResultStateLoading();

  List<PomodoroPreset> get presets => _presets;
  ResultState<List<PomodoroPreset>> get state => _state;

  Future<void> loadPresets() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _state = ResultStateError(Exception('Not authenticated'), 'Not authenticated');
      notifyListeners();
      return;
    }
    _repository.getPresets(userId).listen((result) {
      _state = result;
      if (result is ResultStateSuccess<List<PomodoroPreset>>) {
        _presets = result.data;
      }
      notifyListeners();
    });
  }

  Future<void> createPreset(PomodoroPreset preset) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final withOwner = preset.copyWith(ownerId: userId);
    _repository.createPreset(withOwner).listen((result) {
      if (result is ResultStateSuccess<void>) loadPresets();
    });
  }

  Future<void> updatePreset(PomodoroPreset preset) async {
    _repository.updatePreset(preset).listen((result) {
      if (result is ResultStateSuccess<void>) loadPresets();
    });
  }

  Future<void> deletePreset(String presetId) async {
    _repository.deletePreset(presetId).listen((result) {
      if (result is ResultStateSuccess<void>) loadPresets();
    });
  }

  // ── Sessions ───────────────────────────────────────────────────────────────

  List<PomodoroSession> _sessions = [];
  List<PomodoroSession> get sessions => _sessions;

  Future<void> loadSessions() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    _repository.getSessions(userId).listen((result) {
      if (result is ResultStateSuccess<List<PomodoroSession>>) {
        _sessions = result.data;
        notifyListeners();
      }
    });
  }

  Future<void> saveSession(String mode, int durationMinutes) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final session = PomodoroSession(
      ownerId: userId,
      mode: mode,
      durationMinutes: durationMinutes,
      completedAt: DateTime.now(),
    );
    _repository.saveSession(session).listen((result) {
      if (result is ResultStateSuccess<void>) loadSessions();
    });
  }

  Future<void> deleteSession(String sessionId) async {
    _repository.deleteSession(sessionId).listen((result) {
      if (result is ResultStateSuccess<void>) loadSessions();
    });
  }
}
