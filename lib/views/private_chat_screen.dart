import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ajarin_ya/models/barter_request.dart';
import 'package:ajarin_ya/models/chat_message.dart';
import 'package:ajarin_ya/models/result_state.dart';
import 'package:ajarin_ya/viewmodels/auth_view_model.dart';
import 'package:ajarin_ya/viewmodels/chat_view_model.dart';
import 'package:ajarin_ya/theme/app_theme.dart';
import 'package:ajarin_ya/widgets/full_screen_image_viewer.dart';

class PrivateChatScreen extends StatefulWidget {
  final BarterRequest barterRequest;

  const PrivateChatScreen({super.key, required this.barterRequest});

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatViewModel>().subscribeToMessages(widget.barterRequest.requestId);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    // Use addPostFrameCallback or Future.microtask to avoid modifying provider state during dispose of widget tree
    Future.microtask(() {
      if (mounted) {
        context.read<ChatViewModel>().unsubscribeFromMessages();
      }
    });
    super.dispose();
  }

  String _getOtherParticipantName(String currentUserId) {
    if (widget.barterRequest.userId == currentUserId) {
      // We are the creator, the other is matchedWith
      // Unfortunately we don't have matchedWithName in the model right now, so we can just say "Match Anda"
      return 'Match Mentor Anda';
    } else {
      // We are the matchedWith, the other is the creator
      return widget.barterRequest.userName ?? 'Mentor';
    }
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri Foto'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Kamera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
    if (image == null) return;

    if (!mounted) return;
    
    // Optional: show a dialog to preview image and add caption
    final text = _textController.text;
    _textController.clear();

    final user = context.read<AuthViewModel>().user;
    if (user == null) return;

    await context.read<ChatViewModel>().sendImageMessage(
      widget.barterRequest.requestId,
      user.uid,
      user.displayName,
      user.avatarUrl,
      image,
      text: text,
    );
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final user = context.read<AuthViewModel>().user;
    if (user == null) return;

    _textController.clear();
    context.read<ChatViewModel>().sendTextMessage(
      widget.barterRequest.requestId,
      user.uid,
      user.displayName,
      user.avatarUrl,
      text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthViewModel>().user?.uid ?? '';
    final chatVm = context.watch<ChatViewModel>();
    final state = chatVm.messagesState;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getOtherParticipantName(currentUserId), style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            const Text('Private Barter Chat', style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(state, currentUserId),
          ),
          if (chatVm.sendMessageState is ResultStateLoading)
            const LinearProgressIndicator(minHeight: 2),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessagesList(ResultState<List<ChatMessage>> state, String currentUserId) {
    if (state is ResultStateLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is ResultStateError) {
      return Center(child: Text('Error: ${(state as ResultStateError).message}'));
    } else if (state is ResultStateSuccess<List<ChatMessage>>) {
      final messages = state.data;
      if (messages.isEmpty) {
        return const Center(
          child: Text('Belum ada pesan. Sapa match kamu sekarang!', style: TextStyle(color: Colors.grey)),
        );
      }

      return ListView.builder(
        reverse: true, // Karena di repository kita order descending
        controller: _scrollController,
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          final isMe = message.senderId == currentUserId;
          return _buildChatBubble(message, isMe);
        },
      );
    }

    return const SizedBox();
  }

  Widget _buildChatBubble(ChatMessage message, bool isMe) {
    final hh = message.timestamp.hour.toString().padLeft(2, '0');
    final mm = message.timestamp.minute.toString().padLeft(2, '0');
    final timeStr = '$hh:$mm';

    final bubble = Container(
      margin: EdgeInsets.only(top: 4, bottom: 4, left: isMe ? 40 : 8, right: isMe ? 8 : 40),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: isMe ? AppTheme.primaryColor : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
          bottomRight: isMe ? Radius.zero : const Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Text(
              message.senderName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.blue.shade800,
              ),
            ),
          if (!isMe && message.senderName.isNotEmpty) const SizedBox(height: 4),
          
          if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FullScreenImageViewer(imageUrl: message.imageUrl!, heroTag: message.id.isNotEmpty ? message.id : message.imageUrl!)),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Hero(
                  tag: message.id.isNotEmpty ? message.id : message.imageUrl!,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      message.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
                    ),
                  ),
                ),
              ),
            ),
            
          if (message.text != null && message.text!.isNotEmpty)
            Text(
              message.text!,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 14),
            ),
            
          const SizedBox(height: 4),
          Text(
            timeStr,
            style: TextStyle(
              color: isMe ? Colors.white70 : Colors.black45,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );

    if (isMe) {
      return Align(
        alignment: Alignment.centerRight,
        child: bubble,
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.accentColor.withValues(alpha: 0.2),
              backgroundImage: message.senderAvatarUrl != null && message.senderAvatarUrl!.isNotEmpty 
                  ? NetworkImage(message.senderAvatarUrl!) 
                  : null,
              child: message.senderAvatarUrl == null || message.senderAvatarUrl!.isEmpty
                  ? Text(
                      message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 12),
                    )
                  : null,
            ),
            Flexible(child: bubble),
          ],
        ),
      );
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.image, color: AppTheme.primaryColor),
              onPressed: _pickImage,
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Ketik pesan...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 4,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: AppTheme.primaryColor),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
