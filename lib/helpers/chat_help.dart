import 'package:chat_box/models/message.dart';
import 'package:chat_box/models/user_file.dart';
import 'package:chat_box/widgets/chat_message.dart';

ChatMessage userMessage(
  String content, {
  String? tempId,
  List<String>? imageUrls,
  List<UserFile>? files,
}) {
  return ChatMessage(
    message: Message(
      content: content,
      role: 'user',
      imageUrls: imageUrls,
      sequence: -1,
    ),
    tempId: tempId,
  );
}

ChatMessage assistantMessage(
  String content,
  bool isCompleted, {
  String? tempId,
  Function(String)? onRetry,
}) => ChatMessage(
  message: Message(content: content, role: 'assistant', sequence: -1),
  tempId: tempId,
  onRetry: onRetry,
  isStreamingComplete: isCompleted,
);

(String message, String? label) extractLabel(String response) {
  final labelRegExp = RegExp(r'\[(.*?)\]\s*$');
  final match = labelRegExp.firstMatch(response);
  if (match != null) {
    final label = match.group(1);
    final cleanMessage = response.substring(0, match.start).trim();
    return (cleanMessage, label);
  }
  return (response, null);
}
