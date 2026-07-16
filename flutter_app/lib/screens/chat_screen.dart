import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';

import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'group_info_screen.dart';
import 'user_profile_screen.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String title;
  final String? avatarUrl;
  final bool isGroup;

  const ChatScreen({super.key, required this.chatId, required this.title, this.avatarUrl, this.isGroup = false});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _audioRecorder = AudioRecorder();

  List<dynamic> _messages = [];
  bool _loading = true;
  bool _isRecording = false;
  bool _peerTyping = false;
  Timer? _typingDebounce;

  @override
  void initState() {
    super.initState();
    SocketService().openChat(widget.chatId);
    _loadMessages();
    _listenSocket();
  }

  void _listenSocket() {
    final socket = SocketService().socket;
    socket?.on('message:new', (data) {
      if (data['chat'] == widget.chatId || data['chat']?['_id'] == widget.chatId) {
        setState(() => _messages.add(data));
        _scrollToBottom();
      }
    });
    socket?.on('typing:start', (data) {
      if (data['chatId'] == widget.chatId) setState(() => _peerTyping = true);
    });
    socket?.on('typing:stop', (data) {
      if (data['chatId'] == widget.chatId) setState(() => _peerTyping = false);
    });
  }

  Future<void> _loadMessages() async {
    final res = await ApiService().getMessages(widget.chatId);
    setState(() {
      _messages = res.data['messages'];
      _loading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  void _onTextChanged(String value) {
    SocketService().startTyping(widget.chatId);
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 2), () => SocketService().stopTyping(widget.chatId));
  }

  void _sendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final payload = {'chatId': widget.chatId, 'type': 'text', 'text': text};
    SocketService().sendMessage(payload, (ack) {});
    setState(() => _messages.add({'text': text, 'type': 'text', 'sender': {'_id': 'me'}, 'status': 'sending'}));
    _textController.clear();
    SocketService().stopTyping(widget.chatId);
    _scrollToBottom();
  }

  Future<void> _pickAndSendImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final uploadRes = await ApiService().uploadFile(picked.path, 'chat-media');
    SocketService().sendMessage({
      'chatId': widget.chatId,
      'type': 'image',
      'media': {'url': uploadRes.data['url'], 'mimeType': uploadRes.data['mimeType']},
    }, (ack) {});
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        final uploadRes = await ApiService().uploadFile(path, 'voice-notes');
        SocketService().sendMessage({
          'chatId': widget.chatId,
          'type': 'voice_note',
          'media': {'url': uploadRes.data['url']},
        }, (ack) {});
      }
    } else {
      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start(const RecordConfig(), path: 'voice_note.m4a');
        setState(() => _isRecording = true);
      }
    }
  }

  @override
  void dispose() {
    SocketService().closeChat(widget.chatId);
    _typingDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => widget.isGroup
                  ? GroupInfoScreen(chatId: widget.chatId, groupName: widget.title)
                  : UserProfileScreen(userId: widget.chatId, name: widget.title, avatarUrl: widget.avatarUrl),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: DuoColors.surfaceDark2,
                backgroundImage: widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(widget.avatarUrl!)
                    : null,
                child: (widget.avatarUrl == null || widget.avatarUrl!.isEmpty)
                    ? Icon(widget.isGroup ? Icons.groups_rounded : Icons.person_rounded, size: 18)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(_peerTyping ? 'typing…' : 'online', style: TextStyle(fontSize: 12, color: _peerTyping ? DuoColors.cyan : DuoColors.online)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.videocam_rounded), onPressed: () {}),
          IconButton(icon: const Icon(Icons.call_rounded), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) => _buildBubble(_messages[i]),
                  ),
          ),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildBubble(dynamic msg) {
    final isMe = msg['sender']?['_id'] == 'me' || msg['sender']?['isMe'] == true; // replace with real currentUserId check
    final bubbleColor = isMe ? DuoColors.bubbleSent : DuoColors.bubbleReceived;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg['type'] == 'image' && msg['media']?['url'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(imageUrl: msg['media']['url'], width: 220, fit: BoxFit.cover),
              )
            else if (msg['type'] == 'voice_note')
              Row(mainAxisSize: MainAxisSize.min, children: const [
                Icon(Icons.play_circle_fill_rounded, color: Colors.white70),
                SizedBox(width: 8),
                Text('Voice message', style: TextStyle(color: Colors.white70)),
              ])
            else
              Text(msg['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 15)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  msg['createdAt'] != null ? _formatTime(msg['createdAt']) : 'now',
                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.done_all_rounded,
                      size: 15, color: msg['status'] == 'read' ? DuoColors.blueTick : Colors.white54),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }

  Widget _buildComposer() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.add_circle_outline_rounded), onPressed: _pickAndSendImage),
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: DuoColors.surfaceDark2, borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _textController,
                  onChanged: _onTextChanged,
                  minLines: 1,
                  maxLines: 5,
                  decoration: const InputDecoration(hintText: 'Message', border: InputBorder.none),
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _textController.text.trim().isEmpty ? _toggleRecording : _sendText,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: DuoColors.brandGradient,
                  shape: BoxShape.circle,
                  boxShadow: _isRecording ? [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 12)] : null,
                ),
                child: Icon(
                  _textController.text.trim().isEmpty ? (_isRecording ? Icons.stop_rounded : Icons.mic_rounded) : Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
