import 'package:chat_box/repos/supabase.dart';
import 'package:chat_box/models/conversation.dart';

Future<String> initConversation() async {
  final userId = await SupabaseRepository.client.auth.getUser();

  final result =
      await SupabaseRepository.client
          .from('conversation')
          .insert({
            'title': 'New Chat',
            'created_at': DateTime.now().toIso8601String(),
            'user_id': userId.user!.id,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

  return result['id'].toString();
}

Future<void> updateLabel(String conversationId, String label) async {
  await SupabaseRepository.client
      .from('conversation')
      .update({'title': label})
      .eq('id', conversationId);
}

Future<List<Conversation>> getConversation() async {
  final user = await SupabaseRepository.client.auth.getUser();
  final userId = user.user!.id;

  final result = await SupabaseRepository.client
      .from('conversation')
      .select()
      .eq('user_id', userId)
      .order('updated_at', ascending: false)
      .order('created_at', ascending: false);

  return (result as List).map((json) => Conversation.fromJson(json)).toList();
}

Future<void> deleteConversation(String conversationId) async {
  await SupabaseRepository.client
      .from('conversation')
      .delete()
      .eq('id', conversationId);
}

Future<void> notifyConversation(String conversationId) async {
  await SupabaseRepository.client
      .from('conversation')
      .update({'updated_at': DateTime.now().toIso8601String()})
      .eq('id', conversationId);
}

