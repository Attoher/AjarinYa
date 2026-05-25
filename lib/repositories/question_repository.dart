import 'dart:developer' as developer;
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ajarin_ya/models/question.dart';
import 'package:ajarin_ya/models/result_state.dart';

/// Kontrak Repository untuk fitur "Question Forum"
abstract class QuestionRepository {
  Stream<ResultState<void>> createQuestion(Question question);
  Stream<ResultState<List<Question>>> getQuestions();
  Stream<ResultState<void>> updateQuestion(Question question);
  Stream<ResultState<void>> deleteQuestion(String questionId);
  Future<String?> uploadAttachment(File file, String fileName);
}

/// Implementasi QuestionRepository menggunakan Firebase Cloud Firestore
class QuestionRepositoryImpl implements QuestionRepository {
  final FirebaseFirestore? _customDb;

  QuestionRepositoryImpl({FirebaseFirestore? db}) : _customDb = db;

  FirebaseFirestore? get _db {
    try {
      return _customDb ?? FirebaseFirestore.instance;
    } catch (e) {
      developer.log('Firebase Core belum diinisialisasi.', name: 'QUESTIONS_DB', error: e);
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? get _questionsCollection {
    final firestore = _db;
    if (firestore == null) return null;
    return firestore.collection('questions');
  }
  @override
  Stream<ResultState<void>> createQuestion(Question question) async* {
    yield const ResultStateLoading();
    try {
      final collection = _questionsCollection;
      if (collection == null) throw Exception('Firestore tidak tersedia');

      if (question.id.isEmpty) {
        final docRef = await collection.add(question.toJson());
        question.id = docRef.id;
      } else {
        await collection.doc(question.id).set(question.toJson());
      }
      yield const ResultStateSuccess(null);
    } catch (e) {
      developer.log('ERROR createQuestion: $e', name: 'QUESTIONS_DB');
      yield ResultStateError(e as Exception, 'Gagal membuat pertanyaan: $e');
    }
  }

  @override
  Stream<ResultState<List<Question>>> getQuestions() async* {
    yield const ResultStateLoading();
    try {
      final collection = _questionsCollection;
      if (collection == null) throw Exception('Firestore tidak tersedia');

      final querySnapshot = await collection.orderBy('time', descending: true).get();
      final questions = querySnapshot.docs.map((doc) => Question.fromJson(doc.data(), doc.id)).toList();
      yield ResultStateSuccess(questions);
    } catch (e) {
      developer.log('ERROR getQuestions: $e', name: 'QUESTIONS_DB');
      yield ResultStateError(e as Exception, 'Gagal memuat pertanyaan: $e');
    }
  }

  @override
  Stream<ResultState<void>> updateQuestion(Question question) async* {
    yield const ResultStateLoading();
    try {
      if (question.id.isEmpty) throw ArgumentError('question.id tidak boleh kosong');
      
      final collection = _questionsCollection;
      if (collection == null) throw Exception('Firestore tidak tersedia');

      await collection.doc(question.id).set(question.toJson());
      yield const ResultStateSuccess(null);
    } catch (e) {
      developer.log('ERROR updateQuestion: $e', name: 'QUESTIONS_DB');
      yield ResultStateError(e as Exception, 'Gagal mengupdate pertanyaan: $e');
    }
  }

  @override
  Stream<ResultState<void>> deleteQuestion(String questionId) async* {
    yield const ResultStateLoading();
    try {
      if (questionId.isEmpty) throw ArgumentError('questionId tidak boleh kosong');
      
      final collection = _questionsCollection;
      if (collection == null) throw Exception('Firestore tidak tersedia');

      await collection.doc(questionId).delete();
      yield const ResultStateSuccess(null);
    } catch (e) {
      developer.log('ERROR deleteQuestion: $e', name: 'QUESTIONS_DB');
      yield ResultStateError(e as Exception, 'Gagal menghapus pertanyaan: $e');
    }
  }
  @override
  Future<String?> uploadAttachment(File file, String fileName) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('forum_attachments/$fileName');
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      developer.log('Gagal upload attachment: $e', name: 'STORAGE');
      return null;
    }
  }
}
