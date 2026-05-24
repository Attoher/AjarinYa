import 'dart:async';

import 'package:ajarin_ya/models/question.dart';
import 'package:ajarin_ya/models/result_state.dart';
import 'package:ajarin_ya/repositories/question_repository.dart';
import 'package:flutter/material.dart';

class QuestionViewModel extends ChangeNotifier {
  final QuestionRepository _questionRepository;
  StreamSubscription<ResultState<List<Question>>>? _questionsSubscription;
  bool _isDisposed = false;

  List<Question> _questions = [];
  ResultState<List<Question>> _state = const ResultStateLoading();

  QuestionViewModel({QuestionRepository? questionRepository})
    : _questionRepository = questionRepository ?? QuestionRepositoryImpl() {
    WidgetsBinding.instance.addPostFrameCallback((_) => loadQuestions());
  }

  List<Question> get questions => _questions;
  ResultState<List<Question>> get state => _state;

  void loadQuestions() {
    _questionsSubscription?.cancel();
    _questionsSubscription = _questionRepository.getQuestions().listen((
      result,
    ) {
      _state = result;
      if (result is ResultStateSuccess<List<Question>>) {
        _questions = result.data;
      }
      _notifySafely();
    });
  }

  Question? findQuestion(String questionId) {
    for (final question in _questions) {
      if (question.id == questionId) return question;
    }
    return null;
  }

  Future<void> createQuestion(Question question) async {
    if (question.id.isEmpty) {
      question.id = 'local_q_${DateTime.now().millisecondsSinceEpoch}';
    }
    _upsertQuestion(question, insertFirst: true);
    unawaited(
      _syncQuestionAction(_questionRepository.createQuestion(question)),
    );
  }

  Future<void> updateQuestion(Question question) async {
    _upsertQuestion(question);
    unawaited(
      _syncQuestionAction(_questionRepository.updateQuestion(question)),
    );
  }

  Future<void> deleteQuestion(String questionId) async {
    _questions.removeWhere((question) => question.id == questionId);
    _state = ResultStateSuccess(List<Question>.from(_questions));
    _notifySafely();
    unawaited(
      _syncQuestionAction(_questionRepository.deleteQuestion(questionId)),
    );
  }

  Future<void> _syncQuestionAction(Stream<ResultState<void>> action) async {
    try {
      await for (final result in action) {
        if (result is ResultStateSuccess<void>) {
          return;
        }
      }
    } catch (_) {
      return;
    }
  }

  Future<void> toggleUpvote(Question question) async {
    final updated = question.copyWith(
      isUpvoted: !question.isUpvoted,
      votes: question.isUpvoted ? question.votes - 1 : question.votes + 1,
    );
    await updateQuestion(updated);
  }

  Future<void> addReply(String questionId, Reply reply) async {
    final question = findQuestion(questionId);
    if (question == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final replies = List<Reply>.from(question.replies);
    replies.insert(
      0,
      reply.copyWith(
        id: reply.id.isEmpty ? 'ans_$now' : reply.id,
        createdAtMs: now,
        updatedAtMs: now,
      ),
    );

    await updateQuestion(
      question.copyWith(replies: replies, answersCount: replies.length),
    );
  }

  Future<void> updateReply(String questionId, Reply reply) async {
    final question = findQuestion(questionId);
    if (question == null) return;

    final replies = question.replies.map((item) {
      if (item.id != reply.id) return item;
      return reply.copyWith(updatedAtMs: DateTime.now().millisecondsSinceEpoch);
    }).toList();

    await updateQuestion(
      question.copyWith(replies: replies, answersCount: replies.length),
    );
  }

  Future<void> deleteReply(String questionId, String replyId) async {
    final question = findQuestion(questionId);
    if (question == null) return;

    final replies = question.replies
        .where((reply) => reply.id != replyId)
        .toList();
    await updateQuestion(
      question.copyWith(
        replies: replies,
        answersCount: replies.length,
        isSolved: replies.any((reply) => reply.isBest),
      ),
    );
  }

  Future<void> toggleReplyUpvote(String questionId, Reply reply) async {
    await updateReply(questionId, reply.copyWith(votes: reply.votes + 1));
  }

  Future<void> toggleBestReply(String questionId, String replyId) async {
    final question = findQuestion(questionId);
    if (question == null) return;

    final selected = question.replies.firstWhere(
      (reply) => reply.id == replyId,
    );
    final willBeBest = !selected.isBest;
    final replies = question.replies.map((reply) {
      if (reply.id == replyId) {
        return reply.copyWith(isBest: willBeBest);
      }
      return reply.copyWith(isBest: false);
    }).toList();

    await updateQuestion(
      question.copyWith(
        replies: replies,
        isSolved: replies.any((reply) => reply.isBest),
      ),
    );
  }

  void _upsertQuestion(Question question, {bool insertFirst = false}) {
    final idx = _questions.indexWhere((item) => item.id == question.id);
    if (idx == -1) {
      insertFirst ? _questions.insert(0, question) : _questions.add(question);
    } else {
      _questions[idx] = question;
    }
    _state = ResultStateSuccess(List<Question>.from(_questions));
    _notifySafely();
  }

  void _notifySafely() {
    if (_isDisposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _questionsSubscription?.cancel();
    super.dispose();
  }
}
