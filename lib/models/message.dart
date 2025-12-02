import 'package:chat_box/models/user_file.dart';

class Message {
  final String? id;
  final String content;
  final DateTime? timestamp;
  List<String>? imageUrls;

  List<UserFile>? files;

  final String role;
  final int sequence;

  get isUserMessage => role == 'user';

  Message({
    this.id,
    required this.content,
    required this.role,
    this.sequence = 0,
    this.timestamp,
    this.imageUrls,
    this.files,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'].toString(),
      content: json['content'] as String,
      role: json['role'] as String,
      timestamp: DateTime.parse(json['sent_at'] as String),
      sequence: json['sequence'] as int? ?? 0,
      imageUrls:
          json['images'] != null ? List<String>.from(json['images']) : null,
      files:
          json['files'] != null
              ? (json['files'] as List)
                  .map((file) => UserFile.fromJson(file))
                  .toList()
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'content': content, 'role': role, 'imageUrls': imageUrls};
  }

  @override
  String toString() {
    return "Message{id: $id, content: $content, timestamp: $timestamp, role: $role}";
  }
}
