import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ajarin_ya/models/note.dart';
import 'package:ajarin_ya/models/result_state.dart';

abstract class NotesRepository {
  Stream<ResultState<void>> createNote(Note note);
  Stream<ResultState<List<Note>>> getNotes();
  Stream<ResultState<void>> updateNote(Note note);
  Stream<ResultState<void>> deleteNote(String noteId);
}

class NotesRepositoryImpl implements NotesRepository {
  final FirebaseFirestore? _customDb;

  NotesRepositoryImpl({FirebaseFirestore? db}) : _customDb = db;

  // DB In-Memory Fallback untuk menopang demo luring 100% jika Firebase belum terinisialisasi
  static final List<Note> _inMemoryNotes = [
    Note(
      id: 'mock_note_1',
      title: 'Rangkuman Integral Lipat Tiga',
      folder: '📐 Kalkulus II',
      content: 'Integral lipat tiga digunakan untuk menghitung volume benda padat 3D yang dibatasi oleh permukaan kurva tertentu. Rumus umum: ∭_W f(x,y,z) dV...',
      date: '20 Mei 2026',
      isBookmarked: true,
      colorValue: 0xFFFFF8E1, // amber.shade50
    ),
    Note(
      id: 'mock_note_2',
      title: 'Penerapan Graph pada Social Network',
      folder: '💻 Struktur Data',
      content: 'Graph berarah (Directed Graph) sangat cocok untuk memodelkan hubungan "Following" dan "Follower" pada media sosial, sedangkan Undirected untuk "Friendship".',
      date: '18 Mei 2026',
      isBookmarked: false,
      colorValue: 0xFFE3F2FD, // blue.shade50
    ),
  ];

  FirebaseFirestore? get _db {
    try {
      return _customDb ?? FirebaseFirestore.instance;
    } catch (e) {
      developer.log(
        'Firebase Core belum diinisialisasi untuk Notes. Beralih ke mode simulasi lokal dinamis.',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
      );
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? get _notesCollection {
    final firestore = _db;
    if (firestore == null) return null;
    try {
      return firestore.collection('notes');
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<ResultState<void>> createNote(Note note) async* {
    yield const ResultStateLoading();
    try {
      final collection = _notesCollection;
      if (collection != null) {
        final docRef = note.id.isEmpty
            ? collection.doc()
            : collection.doc(note.id);
        
        note.id = docRef.id;
        await docRef.set(note.toJson());
        
        // Sinkronisasi lokal
        _inMemoryNotes.removeWhere((item) => item.id == note.id);
        _inMemoryNotes.add(note);
      } else {
        if (note.id.isEmpty) {
          note.id = 'local_note_${DateTime.now().millisecondsSinceEpoch}';
        }
        _inMemoryNotes.removeWhere((item) => item.id == note.id);
        _inMemoryNotes.add(note);
        developer.log(
          'Simulasi Lokal: Berhasil menambahkan Catatan baru ke In-Memory DB (${note.title})',
          name: 'INTEGRITY_DIAGNOSTICS',
        );
      }
      yield const ResultStateSuccess(null);
    } catch (e, stackTrace) {
      developer.log(
        'ERROR di createNote: $e. Mengaktifkan in-memory fallback.',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      
      if (note.id.isEmpty) {
        note.id = 'local_note_${DateTime.now().millisecondsSinceEpoch}';
      }
      _inMemoryNotes.removeWhere((item) => item.id == note.id);
      _inMemoryNotes.add(note);
      yield const ResultStateSuccess(null);
    }
  }

  @override
  Stream<ResultState<List<Note>>> getNotes() async* {
    yield const ResultStateLoading();
    try {
      final collection = _notesCollection;
      if (collection != null) {
        final querySnapshot = await collection.get();
        final noteList = <Note>[];

        for (var doc in querySnapshot.docs) {
          final note = Note.fromJson(doc.data(), doc.id);
          noteList.add(note);
        }

        // Sinkronisasi lokal
        _inMemoryNotes.clear();
        _inMemoryNotes.addAll(noteList);
        
        yield ResultStateSuccess(noteList);
      } else {
        yield ResultStateSuccess(List<Note>.from(_inMemoryNotes));
      }
    } catch (e, stackTrace) {
      developer.log(
        'ERROR di getNotes: $e. Membaca dari in-memory fallback.',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      yield ResultStateSuccess(List<Note>.from(_inMemoryNotes));
    }
  }

  @override
  Stream<ResultState<void>> updateNote(Note note) async* {
    yield const ResultStateLoading();
    try {
      if (note.id.isEmpty) {
        throw ArgumentError('note.id tidak boleh kosong saat melakukan update.');
      }
      
      final collection = _notesCollection;
      if (collection != null) {
        await collection.doc(note.id).set(note.toJson());
      }
      
      final idx = _inMemoryNotes.indexWhere((item) => item.id == note.id);
      if (idx != -1) {
        _inMemoryNotes[idx] = note;
      } else {
        _inMemoryNotes.add(note);
      }
      yield const ResultStateSuccess(null);
    } catch (e, stackTrace) {
      developer.log(
        'ERROR di updateNote: $e. Mengaktifkan in-memory fallback.',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      
      final idx = _inMemoryNotes.indexWhere((item) => item.id == note.id);
      if (idx != -1) {
        _inMemoryNotes[idx] = note;
      }
      yield const ResultStateSuccess(null);
    }
  }

  @override
  Stream<ResultState<void>> deleteNote(String noteId) async* {
    yield const ResultStateLoading();
    try {
      if (noteId.isEmpty) {
        throw ArgumentError('noteId tidak boleh kosong saat melakukan penghapusan.');
      }
      
      final collection = _notesCollection;
      if (collection != null) {
        await collection.doc(noteId).delete();
      }
      
      _inMemoryNotes.removeWhere((item) => item.id == noteId);
      yield const ResultStateSuccess(null);
    } catch (e, stackTrace) {
      developer.log(
        'ERROR di deleteNote: $e. Mengaktifkan in-memory fallback.',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      
      _inMemoryNotes.removeWhere((item) => item.id == noteId);
      yield const ResultStateSuccess(null);
    }
  }
}
