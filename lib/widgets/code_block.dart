import 'package:chat_box/constants/code_theme.dart';
import 'package:chat_box/providers/codetheme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CodeBlockWidget extends ConsumerWidget {
  final String code;
  final String language;
  final bool isLoading; // Thêm parameter

  const CodeBlockWidget({
    super.key,
    required this.code,
    required this.language,
    this.isLoading = false, // Mặc định là false
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(codeThemeProvider);
    return Container(
      key: ValueKey(
        'codeblock-$language-${code.hashCode}',
      ), // Important for unique identification
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 6.0,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7.0),
                topRight: Radius.circular(7.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language.isNotEmpty ? language.toUpperCase() : 'CODE',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                    fontSize: 12.0,
                  ),
                ),
                if (isLoading) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.blue.shade400,
                    ),
                  ),
                ],
                CopyButton(code: code),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 500,
              child: HighlightView(
                code,
                language: language.isNotEmpty ? language : 'plaintext',
                theme: codeThemes[currentTheme] ?? atomOneDarkTheme,
                textStyle: const TextStyle(
                  fontFamily: 'Roboto Mono',
                  fontSize: 15.0,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 12.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CopyButton extends StatefulWidget {
  final String code;
  final double? size;

  const CopyButton({super.key, required this.code, this.size = 18.0});

  @override
  State<CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<CopyButton> {
  bool _copied = false;

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.code));
    setState(() {
      _copied = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _copied ? 'Copied' : 'Copy',
      child: IconButton(
        icon: Icon(
          _copied ? Icons.check : Icons.copy,
          size: widget.size,
          color:
              _copied ? Colors.green : const Color.fromARGB(255, 108, 158, 187),
        ),
        onPressed: _copyToClipboard,
        splashRadius: 20.0,
        constraints: const BoxConstraints(minWidth: 32.0, minHeight: 32.0),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
