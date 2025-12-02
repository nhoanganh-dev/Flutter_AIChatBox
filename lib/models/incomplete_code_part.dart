import 'package:chat_box/models/message_content_part.dart';

class IncompleteCodePart extends MessageContentPart {
  final String code;
  final String language;

  IncompleteCodePart(this.code, this.language);
}
