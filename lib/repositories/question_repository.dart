import 'dart:async';
import 'dart:developer' as developer;

import 'package:ajarin_ya/models/question.dart';
import 'package:ajarin_ya/models/result_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class QuestionRepository {
  Stream<ResultState<void>> createQuestion(Question question);
  Stream<ResultState<List<Question>>> getQuestions();
  Stream<ResultState<void>> updateQuestion(Question question);
  Stream<ResultState<void>> deleteQuestion(String questionId);
}

class QuestionRepositoryImpl implements QuestionRepository {
  final FirebaseFirestore? _customDb;

  QuestionRepositoryImpl({FirebaseFirestore? db}) : _customDb = db;

  // Firestore menjadi sumber utama. Fallback lokal tetap ada supaya demo tidak
  // berhenti total saat koneksi atau rules Firebase bermasalah.
  static const bool _forceLocalForumDemo = false;

  static final List<Question> _inMemoryQuestions = [
    Question(
      id: 'q_1',
      author: 'Faisal Rahman (Teknik Mesin)',
      avatar: 'F',
      title:
          'Bagaimana cara mencari titik berat pada pelat setengah lingkaran?',
      content:
          'Halo teman-teman! Saya sedang mengerjakan tugas Fisika Dasar tentang momen inersia dan pusat massa. Ada yang tahu rumus integrasi cepat untuk titik berat pelat setengah lingkaran homogen dengan jari-jari R?',
      tag: 'Fisika',
      votes: 15,
      answersCount: 2,
      time: '2 jam yang lalu',
      isSolved: true,
      createdAtMs: DateTime.now()
          .subtract(const Duration(hours: 2))
          .millisecondsSinceEpoch,
      replies: [
        Reply(
          id: 'a_1',
          author: 'Alika Rahma (Teknik Sipil)',
          content:
              'Gunakan rumus y_bar = 4R / (3 * pi). Ini didapatkan dari integrasi elemen koordinat kutub r dari 0 sampai R, dan theta dari 0 sampai pi.',
          votes: 12,
          isBest: true,
        ),
        Reply(
          id: 'a_2',
          author: 'Rudi Hermawan (Teknik Fisika)',
          content:
              'Betul kata Alika, penjelasannya lengkap ada di buku Halliday edisi 10 bab 9.',
          votes: 3,
        ),
      ],
    ),
    Question(
      id: 'q_2',
      author: 'Gita Larasati (Sains Data)',
      avatar: 'G',
      title: 'Provider tidak update setelah notifyListeners()',
      content:
          'Saya membuat custom ChangeNotifier di Flutter, tetapi ketika memanggil notifyListeners() di method async, UI tidak rebuild secara instan. Apakah harus memanggil setState() juga di view?',
      tag: 'Flutter',
      votes: 8,
      answersCount: 1,
      time: '5 jam yang lalu',
      createdAtMs: DateTime.now()
          .subtract(const Duration(hours: 5))
          .millisecondsSinceEpoch,
      replies: [
        Reply(
          id: 'a_3',
          author: 'Doni Kusuma (Teknik Informatika)',
          content:
              'Pastikan widget dibungkus Consumer atau memakai context.watch<MyViewModel>() di build. Kalau dari initState, pakai context.read dan panggil method setelah frame pertama.',
          votes: 5,
        ),
      ],
    ),
    Question(
      id: 'q_3',
      author: 'Hendra Wijaya (Teknik Material)',
      avatar: 'H',
      title: 'Mengapa korosi sumuran lebih berbahaya dibanding korosi seragam?',
      content:
          'Untuk mata kuliah degradasi material, saya masih bingung kenapa korosi pitting diklasifikasikan sangat fatal padahal luas permukaannya kecil dibanding korosi merata.',
      tag: 'Kimia',
      votes: 22,
      answersCount: 0,
      time: '1 hari yang lalu',
      createdAtMs: DateTime.now()
          .subtract(const Duration(days: 1))
          .millisecondsSinceEpoch,
      replies: [],
    ),
  ];

  FirebaseFirestore? get _db {
    try {
      return _customDb ?? FirebaseFirestore.instance;
    } catch (e) {
      developer.log(
        'Firebase belum siap untuk Questions. Beralih ke in-memory fallback.',
        name: 'FORUM_REPOSITORY',
        error: e,
      );
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? get _questionsCollection {
    if (_forceLocalForumDemo) return null;

    final firestore = _db;
    if (firestore == null) return null;
    try {
      return firestore.collection('questions');
    } catch (e) {
      developer.log(
        'Questions collection tidak bisa diakses. Fallback lokal aktif.',
        name: 'FORUM_REPOSITORY',
        error: e,
      );
      return null;
    }
  }

  @override
  Stream<ResultState<void>> createQuestion(Question question) async* {
    yield const ResultStateLoading();
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      question.createdAtMs = question.createdAtMs == 0
          ? now
          : question.createdAtMs;
      question.updatedAtMs = now;

      final collection = _questionsCollection;
      if (collection != null) {
        final docRef = question.id.isEmpty
            ? collection.doc()
            : collection.doc(question.id);
        question.id = docRef.id;
        await docRef.set(question.toJson()).timeout(const Duration(seconds: 6));
      }

      _upsertLocal(question, insertFirst: true);
      yield const ResultStateSuccess(null);
    } catch (e, stackTrace) {
      developer.log(
        'createQuestion gagal, menyimpan ke fallback lokal.',
        name: 'FORUM_REPOSITORY',
        error: e,
        stackTrace: stackTrace,
      );
      if (question.id.isEmpty) {
        question.id = 'local_q_${DateTime.now().millisecondsSinceEpoch}';
      }
      _upsertLocal(question, insertFirst: true);
      yield const ResultStateSuccess(null);
    }
  }

  @override
  Stream<ResultState<List<Question>>> getQuestions() async* {
    yield const ResultStateLoading();
    yield ResultStateSuccess(_sortedLocalQuestions());

    final collection = _questionsCollection;
    if (collection == null) {
      return;
    }

    try {
      final snapshots = collection.snapshots();
      await for (final snapshot in snapshots) {
        final questionList =
            snapshot.docs
                .map((doc) => Question.fromJson(doc.data(), doc.id))
                .toList()
              ..sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
        _inMemoryQuestions
          ..clear()
          ..addAll(questionList);
        yield ResultStateSuccess(questionList);
      }
    } catch (e, stackTrace) {
      developer.log(
        'Cloud questions belum bisa dibaca. Tetap memakai fallback lokal.',
        name: 'FORUM_REPOSITORY',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Stream<ResultState<void>> updateQuestion(Question question) async* {
    yield const ResultStateLoading();
    try {
      if (question.id.isEmpty) {
        throw ArgumentError('question.id tidak boleh kosong saat update.');
      }

      question.updatedAtMs = DateTime.now().millisecondsSinceEpoch;
      question.answersCount = question.replies.length;
      question.isSolved = question.replies.any((reply) => reply.isBest);

      final collection = _questionsCollection;
      if (collection != null) {
        await collection
            .doc(question.id)
            .set(question.toJson())
            .timeout(const Duration(seconds: 6));
      }

      _upsertLocal(question);
      yield const ResultStateSuccess(null);
    } catch (e, stackTrace) {
      developer.log(
        'updateQuestion gagal, memakai fallback lokal.',
        name: 'FORUM_REPOSITORY',
        error: e,
        stackTrace: stackTrace,
      );
      _upsertLocal(question);
      yield const ResultStateSuccess(null);
    }
  }

  @override
  Stream<ResultState<void>> deleteQuestion(String questionId) async* {
    yield const ResultStateLoading();
    try {
      if (questionId.isEmpty) {
        throw ArgumentError('questionId tidak boleh kosong saat delete.');
      }

      final collection = _questionsCollection;
      if (collection != null) {
        await collection
            .doc(questionId)
            .delete()
            .timeout(const Duration(seconds: 6));
      }

      _inMemoryQuestions.removeWhere((item) => item.id == questionId);
      yield const ResultStateSuccess(null);
    } catch (e, stackTrace) {
      developer.log(
        'deleteQuestion gagal, menghapus dari fallback lokal.',
        name: 'FORUM_REPOSITORY',
        error: e,
        stackTrace: stackTrace,
      );
      _inMemoryQuestions.removeWhere((item) => item.id == questionId);
      yield const ResultStateSuccess(null);
    }
  }

  static void _upsertLocal(Question question, {bool insertFirst = false}) {
    final idx = _inMemoryQuestions.indexWhere((item) => item.id == question.id);
    if (idx != -1) {
      _inMemoryQuestions[idx] = question;
      return;
    }
    insertFirst
        ? _inMemoryQuestions.insert(0, question)
        : _inMemoryQuestions.add(question);
  }

  static List<Question> _sortedLocalQuestions() {
    final copy = List<Question>.from(_inMemoryQuestions)
      ..sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
    return copy;
  }
}
