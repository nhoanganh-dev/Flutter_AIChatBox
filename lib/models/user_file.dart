class UserFile {
  final String? id;
  final String fileId;
  final String name;

  final DateTime? createdAt;

  final String extension;

  UserFile({
    required this.name,
    this.id,
    this.createdAt,
    required this.extension,
    required this.fileId,
  });

  factory UserFile.fromJson(Map<String, dynamic> json) {
    return UserFile(
      name: json['name'] as String,
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      extension: json['extension'] as String,
      fileId: json['file_id'] as String,
    );
  }
}
