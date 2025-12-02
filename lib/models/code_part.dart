import 'package:chat_box/models/message_content_part.dart';

class CodePart extends MessageContentPart {
  final String code;
  final String language;

  CodePart(this.code, this.language);
}
