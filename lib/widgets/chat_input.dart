import 'dart:io';

import 'package:chat_box/providers/chat_state.dart';
import 'package:chat_box/services/openai_service.dart';
import 'package:chat_box/services/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;
import 'package:shimmer/shimmer.dart';

class ChatInput extends ConsumerStatefulWidget {
  final Function(String, {List<AttachmentUpload>? attachments}) onSendMessage;

  final VoidCallback? onStopGenerating;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    this.onStopGenerating,
  });

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput>
    with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  bool _isComposing = false;
  late AnimationController _animationController;
  final _imagePicker = ImagePicker();

  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _animationController.dispose();
    super.dispose();
    _focusNode.dispose();
  }

  void _onTextChanged() {
    final isComposing = _textController.text.isNotEmpty;
    if (isComposing != _isComposing) {
      setState(() {
        _isComposing = isComposing;
      });
      if (isComposing) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFiles = await _imagePicker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      final uniquePaths = pickedFiles.map((file) => file.path).toSet();
      debugPrint(
        'Selected ${pickedFiles.length} images, unique paths: ${uniquePaths.length}',
      );

      for (int i = 0; i < pickedFiles.length; i++) {
        final pickedFile = pickedFiles[i];
        final fileName = path.basename(pickedFile.path);
        debugPrint('Adding attachment: $fileName, path: ${pickedFile.path}');

        final attachment = AttachmentUpload(
          id: "${DateTime.now().millisecondsSinceEpoch}_$i",
          fileName: fileName,
          filePath: pickedFile.path,
          type: AttachmentType.image,
        );
        ref.read(attachmentUploadsProvider.notifier).addAttachment(attachment);
      }
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.image),
                  title: const Text('Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _handleSubmitted() {
    final text = _textController.text.trim();
    final attachments = ref.read(attachmentUploadsProvider);

    final allUploaded = attachments.every(
      (attachment) => attachment.status == UploadStatus.completed,
    );

    if (!allUploaded) {
      // Show a warning if uploads are still in progress
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for uploads to complete'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (text.isEmpty && attachments.isEmpty) return;

    widget.onSendMessage(text, attachments: attachments);
    _textController.clear();
    ref.read(attachmentUploadsProvider.notifier).clearUploads();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(chatStateProvider);
    final attachments = ref.watch(attachmentUploadsProvider);
    final isGenerating = state.isGenerating;

    final hasAttachments = attachments.isNotEmpty;

    final isUploadingImage = ref
        .watch(attachmentUploadsProvider)
        .any((attachment) => attachment.status == UploadStatus.uploading);

    final canSend =
        (_isComposing || hasAttachments) && !isGenerating && !isUploadingImage;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasAttachments)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children:
                    attachments.map((attachment) {
                      return _buildAttachmentPreview(attachment, theme);
                    }).toList(),
              ),
            ),
          ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                // Attachment button
                IconButton(
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: _showAttachmentOptions,
                ),

                // Text field
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.onBackground.withOpacity(0.1),
                      ),
                    ),
                    child: TextField(
                      focusNode: _focusNode,
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onBackground.withOpacity(
                            0.5,
                          ),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => canSend ? _handleSubmitted() : null,
                    ),
                  ),
                ),

                // Send button
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color:
                        canSend
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onBackground.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      state.isGenerating
                          ? Icons.stop_rounded
                          : Icons.send_rounded,
                      color: Colors.white,
                    ),
                    onPressed:
                        canSend
                            ? _handleSubmitted
                            : () {
                              if (isGenerating) {
                                widget.onStopGenerating!();
                              }
                            },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentPreview(AttachmentUpload attachment, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      height: 70,
      width: 70,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.onBackground.withOpacity(0.1),
        ),
      ),
      child: Stack(
        children: [
          // Content preview
          Center(
            child:
                attachment.type == AttachmentType.image
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(
                        File(attachment.filePath),
                        height: 70,
                        width: 70,
                        fit: BoxFit.cover,
                      ),
                    )
                    : Icon(
                      _getFileIcon(attachment.fileName),
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
          ),

          // Upload shimmer loading effect
          if (attachment.status == UploadStatus.uploading ||
              attachment.status == UploadStatus.pending)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Shimmer.fromColors(
                  baseColor: Colors.black.withOpacity(0.2),
                  highlightColor: Colors.black.withOpacity(0.4),
                  child: Container(color: Colors.white),
                ),
              ),
            ),

          // Error indicator
          if (attachment.status == UploadStatus.error)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error, color: Colors.white, size: 12),
              ),
            ),

          // Delete button
          Positioned(
            top: 0,
            right: 0,
            child: InkWell(
              onTap: () {
                ref
                    .read(attachmentUploadsProvider.notifier)
                    .removeAttachment(attachment.id);
              },
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2),
                child: const Icon(Icons.close, color: Colors.white, size: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = path.extension(fileName).toLowerCase();

    switch (extension) {
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
        return Icons.description;
      case '.xls':
      case '.xlsx':
        return Icons.table_chart;
      case '.ppt':
      case '.pptx':
        return Icons.slideshow;
      case '.txt':
        return Icons.text_snippet;
      case '.zip':
      case '.rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }
}

final attachmentUploadsProvider =
    StateNotifierProvider<AttachmentUploadsNotifier, List<AttachmentUpload>>((
      ref,
    ) {
      return AttachmentUploadsNotifier();
    });

class AttachmentUpload {
  final String id;
  final String fileName;
  final String filePath;
  final AttachmentType type;
  final UploadStatus status;
  final String? errorMessage;
  final String? uploadedUrl;

  AttachmentUpload({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.type,
    this.status = UploadStatus.pending,
    this.errorMessage,
    this.uploadedUrl,
  });

  AttachmentUpload copyWith({
    String? id,
    String? fileName,
    String? filePath,
    AttachmentType? type,
    UploadStatus? status,
    String? errorMessage,
    String? uploadedUrl,
  }) {
    return AttachmentUpload(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      type: type ?? this.type,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      uploadedUrl: uploadedUrl ?? this.uploadedUrl,
    );
  }
}

enum AttachmentType { image, file }

enum UploadStatus { pending, uploading, completed, error }

class AttachmentUploadsNotifier extends StateNotifier<List<AttachmentUpload>> {
  AttachmentUploadsNotifier() : super([]);

  void addAttachment(AttachmentUpload attachment) async {
    state = [...state, attachment];

    updateAttachment(attachment.copyWith(status: UploadStatus.uploading));

    try {
      if (attachment.type == AttachmentType.image) {
        final url = await uploadImage(File(attachment.filePath));
        updateAttachment(
          attachment.copyWith(status: UploadStatus.completed, uploadedUrl: url),
        );
      } else if (attachment.type == AttachmentType.file) {
        debugPrint('Uploading file: ${attachment.filePath}');
        final OpenAIService openAIService = OpenAIService();
        final fileId = await openAIService.handleUploadFile(
          file: File(attachment.filePath),
        );
        updateAttachment(
          attachment.copyWith(
            status: UploadStatus.completed,
            uploadedUrl: fileId,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error uploading file: $e');
      updateAttachment(
        attachment.copyWith(
          status: UploadStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void removeAttachment(String id) {
    state = state.where((attachment) => attachment.id != id).toList();
  }

  void updateAttachment(AttachmentUpload updatedAttachment) {
    state =
        state.map((attachment) {
          if (attachment.id == updatedAttachment.id) {
            return updatedAttachment;
          }
          return attachment;
        }).toList();
  }

  void clearUploads() {
    state = [];
  }
}
