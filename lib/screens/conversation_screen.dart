import 'package:chat_box/models/conversation.dart';
import 'package:chat_box/providers/chat_state.dart';
import 'package:chat_box/providers/fetch_conversation.dart';
import 'package:chat_box/providers/user_provider.dart';
import 'package:chat_box/screens/settings_screen.dart';
import 'package:chat_box/widgets/conversation_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({
    super.key,
    required this.onBack,
    required this.onLoadConversation,
  });

  final VoidCallback onBack;

  final VoidCallback onLoadConversation;

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Conversation> _conversations = [];
  List<Conversation> _filteredConversations = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
  }

  void _filterConversations(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredConversations = _conversations;
      } else {
        _filteredConversations =
            _conversations
                .where(
                  (conv) =>
                      conv.title.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversationAysnc = ref.watch(conversationFetch);
    final user = ref.read(userProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_right),
            onPressed: () {
              widget.onBack();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search conversations',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: _filterConversations,
            ),
          ),

          conversationAysnc.when(
            data: (data) {
              _conversations = data;
              _filteredConversations =
                  _searchQuery.isEmpty
                      ? data
                      : data
                          .where(
                            (conv) => conv.title.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ),
                          )
                          .toList();
              return Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    return ref.refresh(conversationFetch);
                  },
                  child:
                      _filteredConversations.isEmpty
                          ? Center(
                            child:
                                _searchQuery.isEmpty
                                    ? const Text('No conversations yet')
                                    : Text('No results for "$_searchQuery"'),
                          )
                          : ConversationListByDate(
                            onTap: () {
                              widget.onLoadConversation();
                            },
                            conversations: _filteredConversations,
                          ),
                ),
              );
            },

            error: (error, stackTrace) {
              return Center(child: Text('Error: $error'));
            },
            loading: () {
              return Expanded(
                child: Shimmer.fromColors(
                  baseColor: Theme.of(context).colorScheme.surfaceVariant,
                  highlightColor: Theme.of(context).colorScheme.surface,
                  child: ListView.builder(
                    itemCount: 8,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 16.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (index == 0 || index == 3 || index == 6)
                              Container(
                                width: 100,
                                height: 16,
                                margin: const EdgeInsets.only(bottom: 8.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ListTile(
                              title: Container(
                                width: double.infinity,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              subtitle: Container(
                                width: 100,
                                height: 12,
                                margin: const EdgeInsets.only(top: 8.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            Expanded(
              child: ListTile(
                onTap:
                    () => {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      ),
                    },
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                    user.userMetadata!['avatar_url'] ??
                        'https://example.com/default_avatar.png',
                  ),
                  radius: 20,
                ),
                title: Text(
                  user.userMetadata!['full_name'] ?? 'User',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () async {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class ConversationListByDate extends StatelessWidget {
  final List<Conversation> conversations;

  final VoidCallback onTap;

  const ConversationListByDate({
    super.key,
    required this.conversations,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateGroups = _groupConversationsByDate(conversations);

    return ListView.builder(
      itemCount: dateGroups.length,

      itemBuilder: (context, index) {
        final group = dateGroups[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                group.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            ...group.conversations.map(
              (conversation) => ConversationTile(
                conversation: conversation,
                onTap: () {
                  onTap();
                },
              ),
            ),
          ],
        );
      },
    );
  }

  List<DateGroup> _groupConversationsByDate(List<Conversation> conversations) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final lastWeek = today.subtract(const Duration(days: 7));
    final lastMonth = DateTime(now.year, now.month - 1, now.day);
    final thisYear = DateTime(now.year, 1, 1);

    final Map<String, List<Conversation>> groups = {
      'Today': [],
      'Yesterday': [],
      'This Week': [],
      'This Month': [],
      'This Year': [],
      'Older': [],
    };

    for (var conversation in conversations) {
      final date = conversation.updatedAt;
      final conversationDate = DateTime(date.year, date.month, date.day);

      if (conversationDate == today) {
        groups['Today']!.add(conversation);
      } else if (conversationDate == yesterday) {
        groups['Yesterday']!.add(conversation);
      } else if (conversationDate.isAfter(lastWeek)) {
        groups['This Week']!.add(conversation);
      } else if (conversationDate.isAfter(lastMonth)) {
        groups['This Month']!.add(conversation);
      } else if (conversationDate.isAfter(thisYear)) {
        groups['This Year']!.add(conversation);
      } else {
        groups['Older']!.add(conversation);
      }
    }

    final result = <DateGroup>[];
    groups.forEach((title, convs) {
      if (convs.isNotEmpty) {
        result.add(DateGroup(title: title, conversations: convs));
      }
    });

    return result;
  }
}

class DateGroup {
  final String title;
  final List<Conversation> conversations;

  DateGroup({required this.title, required this.conversations});
}

class ConversationTile extends ConsumerWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timeAgo = timeago.format(conversation.updatedAt);

    void showActionSheet() {
      showModalBottomSheet(
        constraints: const BoxConstraints(maxHeight: 150),
        context: context,
        builder: (_) {
          return ConversationAction(conversation: conversation);
        },
      );
    }

    return ListTile(
      onLongPress: () {
        showActionSheet();
      },
      title: Text(conversation.title, style: theme.textTheme.bodyLarge),
      subtitle: Text(
        timeAgo,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: IconButton(
        onPressed: () {
          showActionSheet();
        },
        icon: const Icon(Icons.more_horiz, color: Colors.grey),
        color: theme.colorScheme.onSurface.withOpacity(0.7),
      ),

      onTap: () {
        ref.read(chatStateProvider.notifier).setNewConversation(false);

        ref
            .read(chatStateProvider.notifier)
            .setCurrentConversationId(conversation.id);

        onTap();
      },
    );
  }
}
