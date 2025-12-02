import 'package:chat_box/providers/chat_state.dart';
import 'package:chat_box/widgets/chat_input.dart';
import 'package:chat_box/widgets/optimized_image_grid.dart';
import 'package:flutter/material.dart';
import 'package:chat_box/models/message.dart';
import 'package:chat_box/models/code_part.dart';
import 'package:chat_box/models/message_content_part.dart';
import 'package:chat_box/models/text_part.dart';
import 'package:chat_box/widgets/code_block.dart';
import 'package:chat_box/widgets/enhanced_markdown_body.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatMessage extends ConsumerWidget {
  final Message message;

  final bool isStreamingComplete;
  final String? tempId;

  final void Function(String tempId)? onRetry;

  const ChatMessage({
    super.key,
    required this.message,
    this.tempId,
    this.onRetry,
    this.isStreamingComplete = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUser = message.role == 'user';
    final backgroundColor =
        isUser
            ? Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.7)
            : Theme.of(context).colorScheme.surface;

    final isGenerating = ref.read(chatStateProvider).isGenerating;

    final isUploading = ref
        .read(attachmentUploadsProvider)
        .any((upload) => upload.status == UploadStatus.uploading);

    final canPress = !isGenerating && !isUploading;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (message.imageUrls != null &&
              isUser &&
              message.imageUrls!.isNotEmpty)
            OptimizedImageGrid(imageUrls: message.imageUrls!),
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(12.0),

                  decoration: BoxDecoration(
                    color: backgroundColor,

                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.content.isNotEmpty)
                        PreRenderedMessageContent(content: message.content),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (!isUser && isStreamingComplete)
            Align(
              alignment: Alignment.bottomLeft,
              child: Row(
                children: [
                  CopyButton(code: message.content, size: 12.5),
                  const SizedBox(width: 5),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      iconSize: 15,
                    ),
                    onPressed:
                        canPress
                            ? () {
                              debugPrint(
                                "Retrying message with sequence: ${message.sequence}",
                              );
                              if (onRetry != null) {
                                debugPrint("On retry callback is not null");
                                onRetry!(tempId!);
                              }
                            }
                            : null,
                    icon: Icon(Icons.refresh, size: 15),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class PreRenderedMessageContent extends StatelessWidget {
  final String content;

  const PreRenderedMessageContent({super.key, required this.content});

  List<MessageContentPart> _parseContent(String content) {
    final List<MessageContentPart> parts = [];

    final completeCodeBlockRegex = RegExp(
      r'```([^\n]*)\n([\s\S]*?)```',
      multiLine: true,
    );

    final incompleteCodeBlockRegex = RegExp(
      r'```([^\n]*)\n([\s\S]*)$',
      multiLine: true,
    );

    int lastMatchEnd = 0;
    final matches = completeCodeBlockRegex.allMatches(content).toList();

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        final textSegment = content.substring(lastMatchEnd, match.start);
        if (textSegment.trim().isNotEmpty) {
          parts.add(TextPart(textSegment));
        }
      }

      final language = match.group(1)?.trim() ?? '';
      final codeContent = match.group(2) ?? '';

      if (codeContent.trim().isNotEmpty) {
        parts.add(CodePart(codeContent, language));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < content.length) {
      final remainingText = content.substring(lastMatchEnd);

      if (remainingText.contains('```') &&
          remainingText.startsWith('```') &&
          !remainingText.contains('```', 3)) {
        final incompleteMatch = incompleteCodeBlockRegex.firstMatch(
          remainingText,
        );
        if (incompleteMatch != null) {
          final language = incompleteMatch.group(1)?.trim() ?? '';
          final codeContent = incompleteMatch.group(2) ?? '';

          if (codeContent.trim().isNotEmpty) {
            parts.add(IncompleteCodePart(codeContent, language));
          }
        }
      } else if (remainingText.trim().isNotEmpty) {
        parts.add(TextPart(remainingText));
      }
    }

    if (parts.isEmpty && content.trim().isNotEmpty) {
      parts.add(TextPart(content));
    }

    return parts;
  }

  @override
  Widget build(BuildContext context) {
    final parts = _parseContent(content);

    if (parts.isEmpty) {
      return const SizedBox();
    }

    if (parts.length == 1 && parts.first is TextPart) {
      return EnhancedMarkdownBody(data: (parts.first as TextPart).text);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          parts.map((part) {
            if (part is CodePart) {
              return CodeBlockWidget(code: part.code, language: part.language);
            } else if (part is IncompleteCodePart) {
              return CodeBlockWidget(
                code: part.code,
                language: part.language,
                isLoading: true,
              );
            } else if (part is TextPart) {
              return EnhancedMarkdownBody(data: part.text);
            }
            return const SizedBox();
          }).toList(),
    );
  }
}
