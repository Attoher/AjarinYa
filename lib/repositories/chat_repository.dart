import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ajarin_ya/models/chat_message.dart';
import 'package:ajarin_ya/models/result_state.dart';

abstract class ChatRepository {
  Stream<ResultState<List<ChatMessage>>> streamMessages(String chatId);
  Future<ResultState<void>> sendMessage(String chatId, ChatMessage message);
}

class ChatRepositoryImpl implements ChatRepository {
  final FirebaseFirestore? _db;

  ChatRepositoryImpl({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>>? _messagesCollection(String chatId) {
    if (_db == null) return null;
    return _db.collection('barter_requests').doc(chatId).collection('messages');
  }

  @override
  Stream<ResultState<List<ChatMessage>>> streamMessages(String chatId) async* {
    yield const ResultStateLoading();

    final collection = _messagesCollection(chatId);
    if (collection == null) {
      yield ResultStateError(Exception('Koneksi Firestore tidak tersedia.'), 'Koneksi database (Firestore) tidak tersedia.');
      return;
    }

    try {
      yield* collection.orderBy('timestamp', descending: true).snapshots().map((snapshot) {
        final messages = snapshot.docs.map((doc) => ChatMessage.fromJson(doc.data(), doc.id)).toList();
        return ResultStateSuccess(messages);
      });
    } catch (e) {
      developer.log('ERROR streamMessages: $e', name: 'CHAT_REPO');
      yield ResultStateError(e, 'Gagal mengambil pesan: $e');
    }
  }

  @override
  Future<ResultState<void>> sendMessage(String chatId, ChatMessage message) async {
    try {
      final collection = _messagesCollection(chatId);
      if (collection == null) {
        throw Exception('Firestore tidak tersedia');
      }

      await collection.add(message.toJson());
      return const ResultStateSuccess(null);
    } catch (e) {
      developer.log('ERROR sendMessage: $e', name: 'CHAT_REPO');
      return ResultStateError(e, 'Gagal mengirim pesan: $e');
    }
  }
}
