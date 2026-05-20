import 'package:flutter/material.dart';
import 'package:ajarin_ya/models/note.dart';
import 'package:ajarin_ya/models/result_state.dart';
import 'package:ajarin_ya/repositories/notes_repository.dart';

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
    _notesRepository.getNotes().listen((result) {
      _state = result;
      if (result is ResultStateSuccess<List<Note>>) {
        _notes = result.data;
      }
      notifyListeners();
    });
  }

  Future<void> createNote(Note note) async {
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
