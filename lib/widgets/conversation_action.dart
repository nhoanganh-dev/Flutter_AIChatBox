import 'package:chat_box/models/conversation.dart';
import 'package:chat_box/providers/chat_state.dart';
import 'package:chat_box/providers/fetch_conversation.dart';
import 'package:chat_box/services/conversation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConversationAction extends ConsumerStatefulWidget {
  const ConversationAction({
    super.key,
    required this.conversation,
    this.onEditConversation,
    this.onDeleteConversation,
  });

  final VoidCallback? onEditConversation;
  final VoidCallback? onDeleteConversation;

  final Conversation conversation;

  @override
  ConsumerState<ConversationAction> createState() => _ConversationActionState();
}

class _ConversationActionState extends ConsumerState<ConversationAction> {
  bool isLoading = false;

  void handeDelete(Conversation conversation) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    await deleteConversation(conversation.id);

    ref.invalidate(conversationFetch);
    setState(() {
      isLoading = false;
    });

    if (ref.read(chatStateProvider).currentConversationId == conversation.id) {
      ref.read(chatStateProvider.notifier).setNewConversation(true);

      ref.read(chatStateProvider.notifier).setCurrentConversationId('');
    }

    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  void handleEdit(String label) async {
    if (label.trim().isEmpty) {
      return;
    }
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    await updateLabel(widget.conversation.id, label);

    ref.invalidate(conversationFetch);
    setState(() {
      isLoading = false;
    });
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  void showDeleteConfirmation(Conversation conversation) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Conversation'),
            content: Text(
              'Are you sure you want to delete "${conversation.title}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed:
                    isLoading
                        ? null
                        : () {
                          handeDelete(conversation);
                        },
                child: Text(isLoading ? 'Loading...' : 'Delete'),
              ),
            ],
          ),
    );
  }

  void showEditDialog(Conversation conversation) {
    final TextEditingController titleController = TextEditingController(
      text: conversation.title,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Conversation'),
            content: TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed:
                    isLoading
                        ? null
                        : () {
                          handleEdit(titleController.text);
                        },
                child: Text(isLoading ? 'Loading...' : 'Save'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.edit, color: theme.colorScheme.primary),
            title: Text(
              "Edit Conversation",
              style: theme.textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            onTap: () {
              showEditDialog(widget.conversation);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: theme.colorScheme.error),
            title: Text(
              "Delete Conversation",
              style: theme.textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.error,
              ),
            ),
            onTap: () {
              showDeleteConfirmation(widget.conversation);
            },
          ),
        ],
      ),
    );
  }
}
