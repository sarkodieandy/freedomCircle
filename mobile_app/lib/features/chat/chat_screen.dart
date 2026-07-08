import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../data/models/chat_conversation.dart';
import '../../data/models/chat_message.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/recording_repository.dart';
import '../../data/supabase/supabase_service.dart';
import 'controllers/chat_controller.dart';
import 'controllers/recording_controller.dart';
import 'services/chat_realtime_service.dart';
import 'widgets/chat_empty_state.dart';
import 'widgets/chat_error_state.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/chat_loading_state.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/message_options_sheet.dart';
import 'widgets/online_presence_row.dart';
import 'widgets/typing_indicator.dart';
import 'widgets/voice_message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    this.conversation,
    this.conversationId,
    this.title,
    this.groupId,
    this.allowAnonymous = false,
    this.showModeratorActions = false,
  });

  final ChatConversation? conversation;
  final String? conversationId;
  final String? title;
  final String? groupId;
  final bool allowAnonymous;
  final bool showModeratorActions;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatRepository _repository = const ChatRepository();
  final RecordingRepository _recordingRepository = const RecordingRepository();
  late final ChatController _chatController;
  late final RecordingController _recordingController;
  ChatRealtimeService? _realtimeService;
  StreamSubscription<Map<String, dynamic>>? _typingSubscription;
  Timer? _typingTimer;
  String _typingLabel = '';

  String? get _conversationId => widget.conversation?.id ?? widget.conversationId;

  @override
  void initState() {
    super.initState();
    final conversationId = _conversationId ?? '';
    _chatController = ChatController(
      conversationId: conversationId,
      groupId: widget.groupId ?? widget.conversation?.groupId,
      repository: _repository,
    );
    _recordingController = RecordingController();
    if (conversationId.isNotEmpty) {
      _realtimeService = ChatRealtimeService(conversationId);
      _typingSubscription = _realtimeService!.typingEvents().listen(
        _handleTypingPayload,
      );
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _typingSubscription?.cancel();
    _realtimeService?.dispose();
    _chatController.dispose();
    _recordingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversationId = _conversationId;
    if (conversationId == null || conversationId.isEmpty) {
      return const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: ChatErrorState(
              message: 'Open a group, helper, or support request to start chat.',
            ),
          ),
        ),
      );
    }

    final title = widget.title ??
        widget.conversation?.title ??
        _conversationTitle(widget.conversation?.conversationType);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            onPressed: () => _repository.muteConversation(conversationId),
            icon: const Icon(Icons.notifications_off_outlined),
            tooltip: 'Mute conversation',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: OnlinePresenceRow(
              onlineCount: widget.conversation?.isPrivate == true ? 2 : 18,
              subtitle: _presenceSubtitle(widget.conversation),
              accent: _accent(widget.conversation),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _repository.listenToMessages(conversationId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ChatErrorState(
                    message: snapshot.error.toString(),
                    onRetry: () => setState(() {}),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ChatLoadingState();
                }

                final messages = snapshot.data ?? const <ChatMessage>[];
                _markConversationRead(conversationId, messages);

                if (messages.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: ChatEmptyState(),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  itemCount: messages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return TypingIndicator(label: _typingLabel);
                    }

                    final message = messages[index];
                    final isMine =
                        message.senderId == SupabaseService.currentUserId;
                    return _AnimatedMessage(
                      index: index,
                      child: message.isVoice
                          ? VoiceMessageBubble(
                              message: message,
                              isMine: isMine,
                              onPlay: () => _playVoice(message),
                              onLongPress: () => _showMessageActions(
                                message,
                                isMine,
                              ),
                            )
                          : ChatMessageBubble(
                              message: message,
                              isMine: isMine,
                              onReply: () => _chatController.setReply(message),
                              onReaction: (reaction) =>
                                  _react(message, reaction),
                              onLongPress: () => _showMessageActions(
                                message,
                                isMine,
                              ),
                            ),
                    );
                  },
                );
              },
            ),
          ),
          AnimatedBuilder(
            animation: Listenable.merge([_chatController, _recordingController]),
            builder: (context, _) => ChatInputBar(
              onSend: _chatController.sendText,
              onRecordPressed: _handleRecordPressed,
              onTyping: _sendTyping,
              replyingTo: _chatController.replyingTo,
              onCancelReply: () => _chatController.setReply(null),
              isRecording: _recordingController.state.isRecording,
              isAnonymous: _chatController.isAnonymous,
              onAnonymousChanged:
                  widget.allowAnonymous ? _chatController.setAnonymous : null,
            ),
          ),
        ],
      ),
    );
  }

  void _handleTypingPayload(Map<String, dynamic> payload) {
    final userId = payload['user_id']?.toString();
    if (userId == null || userId == SupabaseService.currentUserId) return;

    final isTyping = payload['is_typing'] == true;
    _typingTimer?.cancel();
    if (!mounted) return;
    setState(() => _typingLabel = isTyping ? 'Someone is typing' : '');
    if (isTyping) {
      _typingTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _typingLabel = '');
      });
    }
  }

  void _sendTyping(bool isTyping) {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;
    _realtimeService?.sendTyping(userId: userId, isTyping: isTyping);
  }

  Future<void> _handleRecordPressed() async {
    if (_recordingController.state.isRecording) {
      final state = await _recordingController.stop();
      if (!mounted) return;
      if (state.localFilePath == null) {
        _showSnack(
          state.error ?? 'Voice recording is ready for the native recorder package.',
        );
        return;
      }

      final conversationId = _conversationId;
      if (conversationId == null) return;
      final filePath = await _recordingRepository.uploadVoiceNote(
        conversationId: conversationId,
        localFilePath: state.localFilePath!,
      );
      final signedUrl = await _recordingRepository.signedVoiceUrl(filePath);
      final message = await _repository.sendVoiceMessage(
        conversationId: conversationId,
        groupId: widget.groupId ?? widget.conversation?.groupId,
        filePath: filePath,
        fileUrl: signedUrl,
        durationSeconds: state.durationSeconds,
        waveform: state.waveform,
        isAnonymous: _chatController.isAnonymous,
      );
      await _recordingRepository.createRecordingMetadata(
        conversationId: conversationId,
        messageId: message.id,
        filePath: filePath,
        fileUrl: signedUrl,
        durationSeconds: state.durationSeconds,
        mimeType: 'audio/mp4',
        consentConfirmed: false,
      );
      return;
    }

    await _recordingController.start();
    if (!mounted) return;
    final error = _recordingController.state.error;
    if (error != null) _showSnack(error);
  }

  Future<void> _showMessageActions(ChatMessage message, bool isMine) {
    return showMessageOptionsSheet(
      context: context,
      message: message,
      isMine: isMine,
      canModerate: widget.showModeratorActions,
      onReply: () => _chatController.setReply(message),
      onReaction: (reaction) => _react(message, reaction),
      onReport: () => _report(message),
      onEdit: isMine ? () => _edit(message) : null,
      onDelete: isMine ? () => _delete(message) : null,
      onHide:
          widget.showModeratorActions ? () => _hideAsModerator(message) : null,
      onBlockUser: message.senderId == null
          ? null
          : () => _repository.blockUser(message.senderId!),
    );
  }

  Future<void> _edit(ChatMessage message) async {
    final controller = TextEditingController(text: message.body ?? '');
    final newBody = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit message'),
        content: TextField(
          controller: controller,
          minLines: 1,
          maxLines: 4,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newBody == null || newBody.trim().isEmpty) return;
    await _repository.editMessage(message.id, newBody);
  }

  Future<void> _delete(ChatMessage message) async {
    await _repository.softDeleteMessage(message.id);
  }

  Future<void> _hideAsModerator(ChatMessage message) async {
    await _repository.hideMessageAsModerator(message.id);
  }

  Future<void> _react(ChatMessage message, String reaction) async {
    await _repository.reactToMessage(message.id, reaction);
  }

  Future<void> _report(ChatMessage message) async {
    await _repository.reportMessage(message.id, 'chat_message');
    if (mounted) _showSnack('Message reported for review.');
  }

  void _playVoice(ChatMessage message) {
    _showSnack(
      message.attachmentUrl == null
          ? 'Voice file is not available yet.'
          : 'Voice playback is ready for the audio player package.',
    );
  }

  void _markConversationRead(String conversationId, List<ChatMessage> messages) {
    if (messages.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repository.markConversationRead(conversationId);
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _conversationTitle(String? type) {
    return switch (type) {
      'prayer_group' => 'Prayer group chat',
      'helper_private' => 'Helper chat',
      'support_request' => 'Support chat',
      'admin_support' => 'Admin support',
      _ => 'Group chat',
    };
  }

  String _presenceSubtitle(ChatConversation? conversation) {
    return switch (conversation?.conversationType) {
      'helper_private' => 'Private helper conversation',
      'support_request' => 'Sensitive support thread',
      'prayer_group' => 'Prayer group members online',
      'admin_support' => 'Admin support placeholder',
      _ => 'Members online now',
    };
  }

  Color _accent(ChatConversation? conversation) {
    return switch (conversation?.conversationType) {
      'helper_private' || 'support_request' => AppColors.support,
      'prayer_group' => AppColors.gold,
      _ => AppColors.green,
    };
  }
}

class _AnimatedMessage extends StatelessWidget {
  const _AnimatedMessage({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 220 + (index % 8) * 24),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
