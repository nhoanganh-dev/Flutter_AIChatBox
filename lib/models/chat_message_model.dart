class ChatMessageRole {
  static const String system = 'system';
  static const String user = 'user';
  static const String assistant = 'assistant';
  static const String dev = 'developer';
}

class ChatMessageModel {
  final String role;
  final String content;
  final List<String>? imageUrls;

  ChatMessageModel({required this.role, required this.content, this.imageUrls});

  Map<String, dynamic> toMap() {
    if (imageUrls != null && imageUrls!.isNotEmpty) {
      List<Map<String, dynamic>> contentArray = [];

      if (content.isNotEmpty) {
        contentArray.add({'type': 'text', 'text': content});
      }

      for (var imageUrl in imageUrls!) {
        contentArray.add({
          'type': 'image_url',
          'image_url': {'url': imageUrl, 'detail': 'auto'},
        });
      }

      return {'role': role, 'content': contentArray};
    } else {
      return {'role': role, 'content': content};
    }
  }
}
