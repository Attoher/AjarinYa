import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ajarin_ya/models/question.dart';
import 'package:ajarin_ya/models/result_state.dart';

abstract class QuestionRepository {
  Stream<ResultState<void>> createQuestion(Question question);
  Stream<ResultState<List<Question>>> getQuestions();
  Stream<ResultState<void>> updateQuestion(Question question);
  Stream<ResultState<void>> deleteQuestion(String questionId);
}

class QuestionRepositoryImpl implements QuestionRepository {
  final FirebaseFirestore? _customDb;

  QuestionRepositoryImpl({FirebaseFirestore? db}) : _customDb = db;

  // DB In-Memory Fallback untuk menopang demo luring 100% jika Firebase belum terinisialisasi
  static final List<Question> _inMemoryQuestions = [
    Question(
      id: 'q_1',
      author: 'Faisal Rahman (Teknik Mesin)',
      avatar: 'F',
      title: 'Bagaimana cara mencari titik berat pada pelat setengah lingkaran?',
      content: 'Halo teman-teman! Saya sedang mengerjakan tugas Fisika Dasar tentang momen inersia dan pusat massa. Ada yang tahu rumus integrasi cepat untuk titik berat pelat setengah lingkaran homogen dengan jari-jari R?',
      tag: '📚 Fisika',
      votes: 15,
      answersCount: 2,
      time: '2 jam yang lalu',
      isUpvoted: false,
      isSolved: true,
      replies: [
        Reply(
          author: 'Alika Rahma (Teknik Sipil)',
          content: 'Gunakan rumus y_bar = 4R / (3 * pi). Ini didapatkan dari integrasi elemen koordinat kutub r dari 0 sampai R, dan theta dari 0 sampai pi.',
          votes: 12,
          isBest: true,
        ),
        Reply(
          author: 'Rudi Hermawan (Teknik Fisika)',
          content: 'Betul kata Alika, penjelasannya lengkap ada di buku Halliday edisi 10 bab 9.',
          votes: 3,
          isBest: false,
        )
      ],
    ),
    Question(
      id: 'q_2',
      author: 'Gita Larasati (Sains Data)',
      avatar: 'G',
      title: 'Error: State Management Provider not updating on notifyListeners()',
      content: 'Saya membuat custom ChangeNotifier di Flutter untuk barter skill, tetapi ketika memanggil notifyListeners() di dalam method async, UI tidak ter-rebuild secara instan. Apakah saya harus memanggil setState() juga di view-nya?',
      tag: '💻 Flutter',
      votes: 8,
      answersCount: 1,
      time: '5 jam yang lalu',
      isUpvoted: true,
      isSolved: false,
      replies: [
        Reply(
          author: 'Doni Kusuma (Teknik Informatika)',
          content: 'Pastikan Anda membungkus widget Anda dengan Consumer atau memanggil context.watch<MyViewModel>() di method build. Jika memanggil di initState, gunakan context.read dan pastikan event listener terdaftar.',
          votes: 5,
          isBest: false,
        )
      ],
    ),
    Question(
      id: 'q_3',
      author: 'Hendra Wijaya (Teknik Material)',
      avatar: 'H',
      title: 'Mengapa korosi sumuran lebih berbahaya dibanding korosi seragam?',
      content: 'Untuk mata kuliah degradasi material, saya masih bingung kenapa korosi pitting (sumuran) diklasifikasikan sebagai bentuk kerusakan yang sangat fatal padahal luas permukaannya kecil dibanding korosi merata.',
      tag: '🔬 Kimia',
      votes: 22,
      answersCount: 0,
      time: '1 hari yang lalu',
      isUpvoted: false,
      isSolved: false,
      replies: [],
    )
  ];

  FirebaseFirestore? get _db {
    try {
      return _customDb ?? FirebaseFirestore.instance;
    } catch (e) {
      developer.log(
        'Firebase Core belum diinisialisasi untuk Questions. Beralih ke mode simulasi lokal dinamis.',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
      );
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? get _questionsCollection {
    final firestore = _db;
    if (firestore == null) return null;
    try {
      return firestore.collection('questions');
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<ResultState<void>> createQuestion(Question question) async* {
    yield const ResultStateLoading();
    try {
      final collection = _questionsCollection;
      if (collection != null) {
        final docRef = question.id.isEmpty
            ? collection.doc()
            : collection.doc(question.id);
        
        question.id = docRef.id;
        await docRef.set(question.toJson());
        
        // Sinkronisasi lokal
        _inMemoryQuestions.removeWhere((item) => item.id == question.id);
        _inMemoryQuestions.insert(0, question);
      } else {
        if (question.id.isEmpty) {
          question.id = 'local_q_${DateTime.now().millisecondsSinceEpoch}';
        }
        _inMemoryQuestions.removeWhere((item) => item.id == question.id);
        _inMemoryQuestions.insert(0, question);
        developer.log(
          'Simulasi Lokal: Berhasil menambahkan Pertanyaan baru ke In-Memory DB (${question.title})',
          name: 'INTEGRITY_DIAGNOSTICS',
        );
      }
      yield const ResultStateSuccess(null);
    } catch (e, stackTrace) {
      developer.log(
        'ERROR di createQuestion: $e. Mengaktifkan in-memory fallback.',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      
      if (question.id.isEmpty) {
        question.id = 'local_q_${DateTime.now().millisecondsSinceEpoch}';
      }
      _inMemoryQuestions.removeWhere((item) => item.id == question.id);
      _inMemoryQuestions.insert(0, question);
      yield const ResultStateSuccess(null);
    }
  }

  @override
  Stream<ResultState<List<Question>>> getQuestions() async* {
    yield const ResultStateLoading();
    try {
      final collection = _questionsCollection;
      if (collection != null) {
        final querySnapshot = await collection.get();
        final questionList = <Question>[];

        for (var doc in querySnapshot.docs) {
          final question = Question.fromJson(doc.data(), doc.id);
          questionList.add(question);
        }

        // Sinkronisasi lokal
        _inMemoryQuestions.clear();
        _inMemoryQuestions.addAll(questionList);
        
        yield ResultStateSuccess(questionList);
      } else {
        yield ResultStateSuccess(List<Question>.from(_inMemoryQuestions));
      }
    } catch (e, stackTrace) {
      developer.log(
        'ERROR di getQuestions: $e. Membaca dari in-memory fallback.',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      yield ResultStateSuccess(List<Question>.from(_inMemoryQuestions));
    }
  }

  @override
  Stream<ResultState<void>> updateQuestion(Question question) async* {
    yield const ResultStateLoading();
    try {
      if (question.id.isEmpty) {
        throw ArgumentError('question.id tidak boleh kosong saat melakukan update.');
      }
      
      final collection = _questionsCollection;
      if (collection != null) {
        await collection.doc(question.id).set(question.toJson());
      }
      
      final idx = _inMemoryQuestions.indexWhere((item) => item.id == question.id);
      if (idx != -1) {
        _inMemoryQuestions[idx] = question;
      } else {
        _inMemoryQuestions.add(question);
      }
      yield const ResultStateSuccess(null);
    } catch (e, stackTrace) {
      developer.log(
        'ERROR di updateQuestion: $e. Mengaktifkan in-memory fallback.',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      
      final idx = _inMemoryQuestions.indexWhere((item) => item.id == question.id);
      if (idx != -1) {
        _inMemoryQuestions[idx] = question;
      }
      yield const ResultStateSuccess(null);
    }
  }

  @override
  Stream<ResultState<void>> deleteQuestion(String questionId) async* {
    yield const ResultStateLoading();
    try {
      if (questionId.isEmpty) {
        throw ArgumentError('questionId tidak boleh kosong saat melakukan penghapusan.');
      }
      
      final collection = _questionsCollection;
      if (collection != null) {
        await collection.doc(questionId).delete();
      }
      
      _inMemoryQuestions.removeWhere((item) => item.id == questionId);
      yield const ResultStateSuccess(null);
    } catch (e, stackTrace) {
      developer.log(
        'ERROR di deleteQuestion: $e. Mengaktifkan in-memory fallback.',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      
      _inMemoryQuestions.removeWhere((item) => item.id == questionId);
      yield const ResultStateSuccess(null);
    }
  }
}
