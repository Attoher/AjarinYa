import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ajarin_ya/models/note.dart';
import 'package:ajarin_ya/models/result_state.dart';
import 'package:ajarin_ya/repositories/notes_repository.dart';

class NotesViewModel extends ChangeNotifier {
  final NotesRepository _notesRepository;

  List<Note> _notes = [];
  ResultState<List<Note>> _state = const ResultStateLoading();

  // =========================
  // Folder Management
  // =========================

  static const List<String> defaultFolders = [
    'Semua Catatan',
    'Umum',
  ];

  List<String> _folders = List.of(defaultFolders);

  List<String> get folders => _folders;

  CollectionReference<Map<String, dynamic>>? get _userDataCol {
    try {
      return FirebaseFirestore.instance.collection('user_data');
    } catch (_) {
      return null;
    }
  }

  NotesViewModel({NotesRepository? notesRepository})
      : _notesRepository = notesRepository ?? NotesRepositoryImpl() {
    loadNotes();
    _loadFolders();
  }

  List<Note> get notes => _notes;
  ResultState<List<Note>> get state => _state;

  // =========================
  // Folder Functions
  // =========================

  Future<void> _loadFolders() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) return;

    try {
      final doc = await _userDataCol?.doc(userId).get();

      if (doc != null && doc.exists) {
        final raw =
        List<String>.from(doc.data()?['noteFolders'] ?? []);

        final merged = {
          ...defaultFolders,
          ...raw,
        }.toList();

        _folders = merged;
        notifyListeners();
      }
    } catch (e) {
      developer.log(
        'ERROR _loadFolders: $e',
        name: 'NOTES_VM',
      );
    }
  }

  Future<void> _saveFolders() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) return;

    try {
      final customFolders = _folders
          .where((f) => !defaultFolders.contains(f))
          .toList();

      await _userDataCol?.doc(userId).set(
        {
          'noteFolders': customFolders,
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      developer.log(
        'ERROR _saveFolders: $e',
        name: 'NOTES_VM',
      );
    }
  }

  Future<bool> addFolder(String name) async {
    final trimmed = name.trim();

    if (trimmed.isEmpty) return false;

    if (_folders.any(
          (f) => f.toLowerCase() == trimmed.toLowerCase(),
    )) {
      return false;
    }

    _folders = [..._folders, trimmed];

    notifyListeners();

    await _saveFolders();

    return true;
  }

  Future<void> deleteFolder(String name) async {
    if (defaultFolders.contains(name)) return;

    final notesToMove =
    _notes.where((note) => note.folder == name).toList();

    for (final note in notesToMove) {
      await updateNote(
        Note(
          id: note.id,
          title: note.title,
          folder: 'Umum',
          content: note.content,
          date: note.date,
          isBookmarked: note.isBookmarked,
          colorValue: note.colorValue,
          ownerId: note.ownerId,
          imageUrl: note.imageUrl,
        ),
      );
    }

    _folders = _folders.where((f) => f != name).toList();

    notifyListeners();

    await _saveFolders();
  }

  // =========================
  // Notes Functions
  // =========================

  Future<void> loadNotes() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      _state = ResultStateError(
        Exception('Not authenticated'),
        'Not authenticated',
      );

      notifyListeners();
      return;
    }

    await for (final result in _notesRepository.getNotes(userId)) {
      _state = result;

      if (result is ResultStateSuccess<List<Note>>) {
        _notes = result.data;
      }

      notifyListeners();
    }
  }

  Future<bool> createNote(Note note) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) return false;

    if (note.ownerId.isEmpty) {
      note = Note(
        id: note.id,
        title: note.title,
        folder: note.folder,
        content: note.content,
        date: note.date,
        isBookmarked: note.isBookmarked,
        colorValue: note.colorValue,
        ownerId: userId,
        imageUrl: note.imageUrl,
      );
    }

    await for (final result in _notesRepository.createNote(note)) {
      if (result is ResultStateSuccess<void>) {
        await loadNotes();
        return true;
      }

      if (result is ResultStateError<void>) {
        return false;
      }
    }

    return false;
  }

  Future<bool> updateNote(Note note) async {
    await for (final result in _notesRepository.updateNote(note)) {
      if (result is ResultStateSuccess<void>) {
        await loadNotes();
        return true;
      }

      if (result is ResultStateError<void>) {
        return false;
      }
    }

    return false;
  }

  Future<bool> deleteNote(String noteId) async {
    await for (final result in _notesRepository.deleteNote(noteId)) {
      if (result is ResultStateSuccess<void>) {
        await loadNotes();
        return true;
      }

      if (result is ResultStateError<void>) {
        return false;
      }
    }

    return false;
  }

  Future<void> toggleBookmark(Note note) async {
    note.isBookmarked = !note.isBookmarked;
    await updateNote(note);
  }
}
