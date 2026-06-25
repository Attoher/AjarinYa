import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ajarin_ya/models/note.dart';
import 'package:ajarin_ya/models/result_state.dart';
import 'package:ajarin_ya/repositories/notes_repository.dart';

class NotesViewModel extends ChangeNotifier {
  final NotesRepository _notesRepository;
  List<Note> _notes = [];
  ResultState<List<Note>> _state = const ResultStateLoading();

  // Default folders always present; custom folders loaded from Firestore.
  static const List<String> defaultFolders = ['Semua Catatan', 'Umum'];
  List<String> _folders = List.of(defaultFolders);
  List<String> get folders => _folders;

  NotesViewModel({NotesRepository? notesRepository})
      : _notesRepository = notesRepository ?? NotesRepositoryImpl() {
    loadNotes();
    _loadFolders();
  }

  List<Note> get notes => _notes;
  ResultState<List<Note>> get state => _state;

  // ── Folders ────────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>>? get _userDataCol {
    try {
      return FirebaseFirestore.instance.collection('user_data');
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadFolders() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    try {
      final doc = await _userDataCol?.doc(userId).get();
      if (doc != null && doc.exists) {
        final raw = List<String>.from(doc.data()?['noteFolders'] ?? []);
        final merged = {...defaultFolders, ...raw}.toList();
        _folders = merged;
        notifyListeners();
      }
    } catch (e) {
      developer.log('ERROR _loadFolders: $e', name: 'NOTES_VM');
    }
  }

  Future<void> _saveFolders() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    try {
      final custom = _folders.where((f) => !defaultFolders.contains(f)).toList();
      await _userDataCol?.doc(userId).set({'noteFolders': custom}, SetOptions(merge: true));
    } catch (e) {
      developer.log('ERROR _saveFolders: $e', name: 'NOTES_VM');
    }
  }

  Future<bool> addFolder(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    if (_folders.any((f) => f.toLowerCase() == trimmed.toLowerCase())) return false;
    _folders = [..._folders, trimmed];
    notifyListeners();
    await _saveFolders();
    return true;
  }

  Future<void> deleteFolder(String name) async {
    if (defaultFolders.contains(name)) return;
    // Move notes in this folder to 'Umum'
    final toMove = _notes.where((n) => n.folder == name).toList();
    for (final note in toMove) {
      await updateNote(Note(
        id: note.id,
        title: note.title,
        folder: 'Umum',
        content: note.content,
        date: note.date,
        isBookmarked: note.isBookmarked,
        colorValue: note.colorValue,
        ownerId: note.ownerId,
        imageUrl: note.imageUrl,
      ));
    }
    _folders = _folders.where((f) => f != name).toList();
    notifyListeners();
    await _saveFolders();
  }

  // ── Notes ──────────────────────────────────────────────────────────────────

  Future<void> loadNotes() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _state = ResultStateError(Exception('Not authenticated'), 'Not authenticated');
      notifyListeners();
      return;
    }

    _notesRepository.getNotes(userId).listen((result) {
      _state = result;
      if (result is ResultStateSuccess<List<Note>>) {
        _notes = result.data;
      }
      notifyListeners();
    });
  }

  Future<void> createNote(Note note) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

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

    _notesRepository.createNote(note).listen((result) {
      if (result is ResultStateSuccess<void>) {
        loadNotes();
      }
    });
  }

  Future<void> updateNote(Note note) async {
    _notesRepository.updateNote(note).listen((result) {
      if (result is ResultStateSuccess<void>) {
        loadNotes();
      }
    });
  }

  Future<void> deleteNote(String noteId) async {
    _notesRepository.deleteNote(noteId).listen((result) {
      if (result is ResultStateSuccess<void>) {
        loadNotes();
      }
    });
  }

  Future<void> toggleBookmark(Note note) async {
    note.isBookmarked = !note.isBookmarked;
    await updateNote(note);
  }
}
