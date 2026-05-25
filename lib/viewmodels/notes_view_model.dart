import 'package:flutter/material.dart';
import 'package:ajarin_ya/models/note.dart';
import 'package:ajarin_ya/models/result_state.dart';
import 'package:ajarin_ya/repositories/notes_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotesViewModel extends ChangeNotifier {
  final NotesRepository _notesRepository;
  List<Note> _notes = [];
  ResultState<List<Note>> _state = const ResultStateLoading();

  NotesViewModel({NotesRepository? notesRepository})
      : _notesRepository = notesRepository ?? NotesRepositoryImpl() {
    loadNotes();
  }

  List<Note> get notes => _notes;
  ResultState<List<Note>> get state => _state;

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
    
    // Assign ownerId if not already set
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
