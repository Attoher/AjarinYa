import 'package:flutter/material.dart';
import 'package:ajarin_ya/models/question.dart';
import 'package:ajarin_ya/models/result_state.dart';
import 'package:ajarin_ya/repositories/question_repository.dart';

class QuestionViewModel extends ChangeNotifier {
  final QuestionRepository _questionRepository;
  List<Question> _questions = [];
  ResultState<List<Question>> _state = const ResultStateLoading();

  QuestionViewModel({QuestionRepository? questionRepository})
      : _questionRepository = questionRepository ?? QuestionRepositoryImpl() {
    loadQuestions();
  }

  List<Question> get questions => _questions;
  ResultState<List<Question>> get state => _state;

  Future<void> loadQuestions() async {
    _questionRepository.getQuestions().listen((result) {
      _state = result;
      if (result is ResultStateSuccess<List<Question>>) {
        _questions = result.data;
      }
      notifyListeners();
    });
  }

  Future<void> createQuestion(Question question) async {
    _questionRepository.createQuestion(question).listen((result) {
      if (result is ResultStateSuccess<void>) {
        loadQuestions();
      }
    });
  }

  Future<void> updateQuestion(Question question) async {
    _questionRepository.updateQuestion(question).listen((result) {
      if (result is ResultStateSuccess<void>) {
        loadQuestions();
      }
    });
  }

  Future<void> deleteQuestion(String questionId) async {
    _questionRepository.deleteQuestion(questionId).listen((result) {
      if (result is ResultStateSuccess<void>) {
        loadQuestions();
      }
    });
  }

  Future<void> toggleUpvote(Question question) async {
    question.isUpvoted = !question.isUpvoted;
    if (question.isUpvoted) {
      question.votes += 1;
    } else {
      question.votes -= 1;
    }
    await updateQuestion(question);
  }

  Future<void> addReply(String questionId, Reply reply) async {
    final idx = _questions.indexWhere((q) => q.id == questionId);
    if (idx != -1) {
      final question = _questions[idx];
      question.replies.add(reply);
      question.answersCount = question.replies.length;
      await updateQuestion(question);
    }
  }

  Future<void> toggleBestReply(String questionId, int replyIdx) async {
    final idx = _questions.indexWhere((q) => q.id == questionId);
    if (idx != -1) {
      final question = _questions[idx];
      if (replyIdx >= 0 && replyIdx < question.replies.length) {
        final reply = question.replies[replyIdx];
        reply.isBest = !reply.isBest;
        
        // Cek apakah ada reply yang bertanda 'isBest'
        question.isSolved = question.replies.any((r) => r.isBest);
        
        await updateQuestion(question);
      }
    }
  }
}
