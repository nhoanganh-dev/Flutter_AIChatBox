import 'package:chat_box/models/message_content_part.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

class EnhancedMarkdownBody extends StatelessWidget {
  final String data;

  const EnhancedMarkdownBody({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return MarkdownBody(
      key: ValueKey('markdown-${data.hashCode}'),
      data: data,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        // Text styling
        p: theme.textTheme.bodyMedium,
        h1: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
        h2: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
        h3: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
        // Lists
        listBullet: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.primary,
        ),
        strong: TextStyle(
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.primary,
        ),
        // Italic text
        em: TextStyle(
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.secondary,
        ),
        // Code within text - improved highlighting
        code: TextStyle(
          backgroundColor: theme.colorScheme.surfaceVariant,
          color: theme.colorScheme.primary,
          fontFamily: 'monospace',
          fontSize: 14.0,
          letterSpacing: -0.3,
          height: 1.2,
        ),
        codeblockPadding: const EdgeInsets.all(8.0), // Better padding
        codeblockDecoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
        ),
        // Links
        a: TextStyle(
          color: theme.colorScheme.tertiary,
          decoration: TextDecoration.underline,
        ),
        // Blockquotes
        blockquote: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.secondary,
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: theme.colorScheme.secondary, width: 4.0),
          ),
        ),
      ),
      // Enhanced inline syntax handling
      inlineSyntaxes: [_KeywordSyntax(), _InlineCodeSyntax()],
      builders: <String, MarkdownElementBuilder>{
        'kbd': _KeyboardSyntaxBuilder(),
        'code': _InlineCodeBuilder(theme),
      },
    );
  }
}

// Custom inline code syntax with enhanced detection
class _InlineCodeSyntax extends md.InlineSyntax {
  _InlineCodeSyntax() : super(r'`([^`\n]+)`');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('code', match[1]!));
    return true;
  }
}

class IncompleteCodePart extends MessageContentPart {
  final String code;
  final String language;

  IncompleteCodePart(this.code, this.language);
}

class _InlineCodeBuilder extends MarkdownElementBuilder {
  final ThemeData theme;

  _InlineCodeBuilder(this.theme);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        element.textContent,
        style: TextStyle(
          fontFamily: 'Roboto Mono',
          fontSize: 14.0,
          color: theme.colorScheme.primary,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

class _KeywordSyntax extends md.InlineSyntax {
  _KeywordSyntax()
    : super(
        r'\b(const|final|var|void|int|String|double|bool|Future|async|await|class|extends|implements)\b',
      );

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('keyword', match[0]!));
    return true;
  }
}

class _KeyboardSyntaxBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Text(
        element.textContent,
        style: preferredStyle?.copyWith(
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
