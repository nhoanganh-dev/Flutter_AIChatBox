import 'package:chat_box/models/message.dart';
import 'package:chat_box/repos/supabase.dart';

Future<Message> createMessage({
  required content,
  required String conversationId,
  required String role,
}) async {
  var response =
      await SupabaseRepository.client
          .from('chat')
          .insert({
            'content': content,
            'role': role,
            'conversation_id': conversationId,
          })
          .select()
          .single();

  return Message.fromJson(response);
}

Future<Message> createUserMessage({
  required String content,
  required String conversationId,
  List<String>? imageUrls,
}) async {
  var response =
      await SupabaseRepository.client
          .from('chat')
          .insert({
            'content': content,
            'role': 'user',
            'conversation_id': conversationId,
            if (imageUrls != null && imageUrls.isNotEmpty) 'images': imageUrls,
          })
          .select()
          .single();

  return Message.fromJson(response);
}

Future<Message> createAssistantMessage({
  required content,
  required String conversationId,
}) async {
  var response = await createMessage(
    content: content,
    conversationId: conversationId,
    role: 'assistant',
  );

  return response;
}

Future<List<Message>> getMessages(String conversationId) async {
  final result = await SupabaseRepository.client
      .from('chat')
      .select('content, role, images, conversation_id, sent_at, sequence, id ')
      .eq('conversation_id', conversationId)
      .order('sent_at', ascending: false);

  final messages =
      (result as List).map((json) => Message.fromJson(json)).toList();
  messages.sort((a, b) => a.timestamp!.compareTo(b.timestamp!));
  return messages;
}

Future<void> deleteMessagesInSequence(
  String conversationId,
  int sequence,
) async {
  try {
    await SupabaseRepository.client
        .from('chat')
        .delete()
        .eq('conversation_id', conversationId)
        .gte('sequence', sequence);
  } catch (e) {
    print('Error deleting messages: $e');
    rethrow;
  }
}
