import 'package:flutter/material.dart';

import '../../../data/models/chat_message.dart';
import 'attachment_picker_sheet.dart';
import 'recording_button.dart';
import 'reply_preview.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.onSend,
    required this.onRecordPressed,
    required this.onTyping,
    this.replyingTo,
    this.onCancelReply,
    this.isRecording = false,
    this.isAnonymous = false,
    this.onAnonymousChanged,
  });

  final ValueChanged<String> onSend;
  final VoidCallback onRecordPressed;
  final ValueChanged<bool> onTyping;
  final ChatMessage? replyingTo;
  final VoidCallback? onCancelReply;
  final bool isRecording;
  final bool isAnonymous;
  final ValueChanged<bool>? onAnonymousChanged;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    widget.onTyping(false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.replyingTo != null)
              ReplyPreview(
                message: widget.replyingTo!,
                onCancel: widget.onCancelReply ?? () {},
              ),
            Row(
              children: [
                IconButton(
                  onPressed: () => showAttachmentPickerSheet(context),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  tooltip: 'Attachment',
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    onChanged: (value) => widget.onTyping(value.isNotEmpty),
                    decoration: InputDecoration(
                      hintText: widget.isAnonymous
                          ? 'Write anonymously...'
                          : 'Write with kindness...',
                    ),
                  ),
                ),
                RecordingButton(
                  isRecording: widget.isRecording,
                  onPressed: widget.onRecordPressed,
                ),
                IconButton.filled(
                  onPressed: _send,
                  icon: const Icon(Icons.send_rounded),
                  tooltip: 'Send',
                ),
              ],
            ),
            if (widget.onAnonymousChanged != null)
              SwitchListTile.adaptive(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Send anonymously'),
                value: widget.isAnonymous,
                onChanged: widget.onAnonymousChanged,
              ),
          ],
        ),
      ),
    );
  }
}
