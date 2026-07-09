import 'package:flutter/material.dart';

import '../../../app/constants.dart';
import '../../../data/models/chat_message.dart';
import 'attachment_picker_sheet.dart';
import 'recording_button.dart';
import 'recording_timer.dart';
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
    this.recordingSeconds = 0,
    this.isAnonymous = false,
    this.onAnonymousChanged,
  });

  final ValueChanged<String> onSend;
  final VoidCallback onRecordPressed;
  final ValueChanged<bool> onTyping;
  final ChatMessage? replyingTo;
  final VoidCallback? onCancelReply;
  final bool isRecording;
  final int recordingSeconds;
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
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.line),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => showAttachmentPickerSheet(context),
                    icon: const Icon(Icons.attach_file_rounded),
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
                            ? 'Send anonymous encouragement...'
                            : 'Write with kindness...',
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  RecordingButton(
                    isRecording: widget.isRecording,
                    onPressed: widget.onRecordPressed,
                  ),
                  IconButton.filled(
                    onPressed: _send,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.send_rounded),
                    tooltip: 'Send',
                  ),
                ],
              ),
            ),
            if (widget.onAnonymousChanged != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch.adaptive(
                        value: widget.isAnonymous,
                        onChanged: widget.onAnonymousChanged,
                      ),
                      const Text('Anonymous'),
                    ],
                  ),
                ),
              ),
            if (widget.isRecording)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.fiber_manual_record_rounded,
                      size: 16,
                      color: AppColors.support,
                    ),
                    const SizedBox(width: 6),
                    RecordingTimer(seconds: widget.recordingSeconds),
                    const SizedBox(width: 8),
                    Text(
                      'Recording voice note...',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
