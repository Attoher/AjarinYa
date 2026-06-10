import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ajarin_ya/models/note.dart';
import 'package:ajarin_ya/models/result_state.dart';

/// Kontrak Repository untuk fitur "Notes / Collection"
abstract class NotesRepository {
  Stream<ResultState<void>> createNote(Note note);
  Stream<ResultState<List<Note>>> getNotes(String ownerId);
  Stream<ResultState<void>> updateNote(Note note);
  Stream<ResultState<void>> deleteNote(String noteId);
}

/// Implementasi NotesRepository menggunakan Firebase Cloud Firestore
class NotesRepositoryImpl implements NotesRepository {
  final FirebaseFirestore? _customDb;

  NotesRepositoryImpl({FirebaseFirestore? db}) : _customDb = db;

  FirebaseFirestore? get _db {
    try {
      return _customDb ?? FirebaseFirestore.instance;
    } catch (e) {
      developer.log('Firebase Core belum diinisialisasi.', name: 'NOTES_DB', error: e);
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? get _notesCollection {
    final firestore = _db;
    if (firestore == null) return null;
    return firestore.collection('notes');
  }
  @override
  Stream<ResultState<void>> createNote(Note note) async* {
    yield const ResultStateLoading();
    try {
      final collection = _notesCollection;
      if (collection == null) throw Exception('Firestore tidak tersedia');

      if (note.id.isEmpty) {
        final docRef = await collection.add(note.toJson());
        note.id = docRef.id;
      } else {
        await collection.doc(note.id).set(note.toJson());
      }
      yield const ResultStateSuccess(null);
    } catch (e) {
      developer.log('ERROR createNote: $e', name: 'NOTES_DB');
      yield ResultStateError(e, 'Gagal menyimpan catatan: $e');
    }
  }

  @override
  Stream<ResultState<List<Note>>> getNotes(String ownerId) async* {
    yield const ResultStateLoading();
    try {
      final collection = _notesCollection;
      if (collection == null) throw Exception('Firestore tidak tersedia');

      final querySnapshot = await collection.where('ownerId', isEqualTo: ownerId).get();
      final notes = querySnapshot.docs.map((doc) => Note.fromJson(doc.data(), doc.id)).toList();
      yield ResultStateSuccess(notes);
    } catch (e) {
      developer.log('ERROR getNotes: $e', name: 'NOTES_DB');
      yield ResultStateError(e, 'Gagal mengambil catatan: $e');
    }
  }

  @override
  Stream<ResultState<void>> updateNote(Note note) async* {
    yield const ResultStateLoading();
    try {
      if (note.id.isEmpty) throw ArgumentError('note.id tidak boleh kosong');
      
      final collection = _notesCollection;
      if (collection == null) throw Exception('Firestore tidak tersedia');

      await collection.doc(note.id).set(note.toJson());
      yield const ResultStateSuccess(null);
    } catch (e) {
      developer.log('ERROR updateNote: $e', name: 'NOTES_DB');
      yield ResultStateError(e, 'Gagal memperbarui catatan: $e');
    }
  }

  @override
  Stream<ResultState<void>> deleteNote(String noteId) async* {
    yield const ResultStateLoading();
    try {
      if (noteId.isEmpty) throw ArgumentError('noteId tidak boleh kosong');
      
      final collection = _notesCollection;
      if (collection == null) throw Exception('Firestore tidak tersedia');

      await collection.doc(noteId).delete();
      yield const ResultStateSuccess(null);
    } catch (e) {
      developer.log('ERROR deleteNote: $e', name: 'NOTES_DB');
      yield ResultStateError(e, 'Gagal menghapus catatan: $e');
    }
  }
}
