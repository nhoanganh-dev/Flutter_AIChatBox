import 'package:chat_box/services/conversation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final conversationFetch = FutureProvider((ref) async {
  final conversations = await getConversation();

  return conversations;
});
