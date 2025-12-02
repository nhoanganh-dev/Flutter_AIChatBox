import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:chat_box/repos/supabase.dart';

Future<String> uploadImage(File file) async {
  try {
    final fileBytes = await file.readAsBytes();
    final extension = file.path.split('.').last;

    final uuid = const Uuid().v4();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final fileName = '${timestamp}_$uuid.$extension';
    final filePath = 'images/$fileName';

    await SupabaseRepository.client.storage
        .from('mystorage')
        .uploadBinary(filePath, fileBytes);

    return getPublicUrl(filePath);
  } catch (e) {
    rethrow;
  }
}

String getPublicUrl(String filePath) {
  final response = SupabaseRepository.client.storage
      .from('mystorage')
      .getPublicUrl(filePath);

  return response;
}
