import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';

class ChatWidget extends StatefulWidget {
  final String trainerId;
  final String clientId;
  final String clientName;
  final List<Map<String, dynamic>> messages;
  final Function(String, String) onSendMessage;

  const ChatWidget({
    Key? key,
    required this.trainerId,
    required this.clientId,
    required this.clientName,
    required this.messages,
    required this.onSendMessage,
  }) : super(key: key);

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final _uuid = const Uuid();
  late types.User _trainer;
  late types.User _client;
  List<types.Message> _chatMessages = [];

  @override
  void initState() {
    super.initState();
    _trainer = types.User(id: widget.trainerId);
    _client = types.User(id: widget.clientId);
    _convertMessages();
  }

  void _convertMessages() {
    _chatMessages = widget.messages.map((msg) {
      return types.TextMessage(
        author: msg['sender_id'] == widget.trainerId ? _trainer : _client,
        createdAt: DateTime.parse(msg['created_at']).millisecondsSinceEpoch,
        id: msg['id'] ?? _uuid.v4(),
        text: msg['content'],
      );
    }).toList();
  }

  @override
  void didUpdateWidget(ChatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messages != widget.messages) {
      _convertMessages();
    }
  }

  void _handleSendPressed(types.PartialText message) {
    widget.onSendMessage(widget.clientId, message.text);
    
    // Add message to local state immediately for better UX
    final textMessage = types.TextMessage(
      author: _trainer,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: _uuid.v4(),
      text: message.text,
    );
    
    setState(() {
      _chatMessages.insert(0, textMessage);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                widget.clientName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.clientName,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Active now',
                  style: TextStyle(
                    color: Colors.green.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_call, color: Colors.blue),
            onPressed: () {
              // Implement video call
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              // Show more options
            },
          ),
        ],
      ),
      body: Chat(
        messages: _chatMessages,
        onSendPressed: _handleSendPressed,
        user: _trainer,
        theme: const DefaultChatTheme(
          primaryColor: Colors.blue,
          inputBackgroundColor: Colors.white,
          inputTextColor: Colors.black,
          inputBorderRadius: BorderRadius.all(Radius.circular(20)),
          messageBorderRadius: 20,
          backgroundColor: Color(0xFFF5F7FA),
        ),
        showUserAvatars: true,
        showUserNames: false,
      ),
    );
  }
}
