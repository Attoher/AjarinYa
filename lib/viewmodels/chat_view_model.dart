import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ajarin_ya/models/chat_message.dart';
import 'package:ajarin_ya/models/result_state.dart';
import 'package:ajarin_ya/repositories/chat_repository.dart';
import 'package:ajarin_ya/services/supabase_storage_service.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatRepository _repository;
  StreamSubscription? _messagesSubscription;
  String? _subscribedUserId;
  Function(ChatMessage)? _onPartnerMessage;
  bool _isInitialLoad = true;

  ChatViewModel({required ChatRepository repository}) : _repository = repository;

  ResultState<List<ChatMessage>> _messagesState = const ResultStateIdle();
  ResultState<List<ChatMessage>> get messagesState => _messagesState;

  ResultState<void> _sendMessageState = const ResultStateIdle();
  ResultState<void> get sendMessageState => _sendMessageState;

  void resetSendMessageState() {
    _sendMessageState = const ResultStateIdle();
    notifyListeners();
  }

  void subscribeToMessages(
    String chatId, {
    String? currentUserId,
    Function(ChatMessage)? onPartnerMessage,
  }) {
    _subscribedUserId = currentUserId;
    _onPartnerMessage = onPartnerMessage;
    _isInitialLoad = true;
    _messagesSubscription?.cancel();
    _messagesState = const ResultStateLoading();
    notifyListeners();

    _messagesSubscription = _repository.streamMessages(chatId).listen(
      (state) {
        if (!_isInitialLoad &&
            state is ResultStateSuccess<List<ChatMessage>> &&
            _messagesState is ResultStateSuccess<List<ChatMessage>>) {
          final oldList =
              (_messagesState as ResultStateSuccess<List<ChatMessage>>).data;
          final newList = state.data;
          if (newList.isNotEmpty &&
              (oldList.isEmpty || newList.first.id != oldList.first.id)) {
            final newest = newList.first;
            if (newest.senderId != _subscribedUserId) {
              _onPartnerMessage?.call(newest);
            }
          }
        }
        _isInitialLoad = false;
        _messagesState = state;
        notifyListeners();
      },
      onError: (e) {
        _messagesState = ResultStateError(e, 'Gagal mendengarkan pesan: $e');
        notifyListeners();
      },
    );
  }

  void unsubscribeFromMessages() {
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
    _onPartnerMessage = null;
    _messagesState = const ResultStateIdle();
    notifyListeners();
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    super.dispose();
  }

  Future<void> sendTextMessage(String chatId, String senderId, String senderName, String? senderAvatarUrl, String text) async {
    _sendMessageState = const ResultStateLoading();
    notifyListeners();

    if (text.trim().isEmpty) {
      _sendMessageState = ResultStateError(ArgumentError('Pesan kosong'), 'Pesan tidak boleh kosong');
      notifyListeners();
      return;
    }

    final message = ChatMessage(
      id: '',
      senderId: senderId,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    _sendMessageState = await _repository.sendMessage(chatId, message);
    notifyListeners();
  }

  Future<void> sendImageMessage(String chatId, String senderId, String senderName, String? senderAvatarUrl, XFile imageFile, {String? text}) async {
    _sendMessageState = const ResultStateLoading();
    notifyListeners();

    final imageUrl = await SupabaseStorageService.instance.uploadChatImage(chatId, imageFile);

    if (imageUrl == null) {
      _sendMessageState = ResultStateError(Exception('Upload gagal'), 'Gagal mengunggah gambar chat.');
      notifyListeners();
      return;
    }

    final message = ChatMessage(
      id: '',
      senderId: senderId,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
      text: text?.trim().isNotEmpty == true ? text!.trim() : null,
      imageUrl: imageUrl,
      timestamp: DateTime.now(),
    );

    _sendMessageState = await _repository.sendMessage(chatId, message);
    notifyListeners();
  }
}
