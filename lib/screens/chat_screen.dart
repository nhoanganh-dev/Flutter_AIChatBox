import 'package:chat_box/constants/dev_message.dart';
import 'package:chat_box/helpers/chat_help.dart';
import 'package:chat_box/models/chat_message_model.dart';
import 'package:chat_box/models/message.dart';
import 'package:chat_box/providers/chat_state.dart';
import 'package:chat_box/providers/fetch_conversation.dart';
import 'package:chat_box/services/conversation.dart';
import 'package:chat_box/services/message.dart';
import 'package:chat_box/widgets/chat_input.dart';
import 'package:chat_box/widgets/empty_chat.dart';
import 'package:chat_box/widgets/model_selection.dart';
import 'package:flutter/material.dart';
import '../widgets/chat_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/openai_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, this.onBack, this.onNew});

  final VoidCallback? onBack;
  final VoidCallback? onNew;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final List<ChatMessageModel> _chatHistory = [];
  String _partialResponse = '';

  final Map<String, int> _sequenceMap = {};

  int _tempMessageCounter = 0;

  final OpenAIService _openAIService = OpenAIService();

  late String conversationId;

  String newLabel = '';

  bool _firstLabel = false;

  late bool isNewConversation;

  var _text = '';
  bool _isLoading = false;

  String model = 'gpt-4.1-mini';

  @override
  void initState() {
    super.initState();

    _setupChat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _setupChat();
  }

  void _onRetryTap(String retryTempId) {
    final realSequence = _sequenceMap[retryTempId];
    if (realSequence != null) {
      final index = _messages.indexWhere((m) => m.tempId == retryTempId);
      if (index != -1) {
        _handleRetryMessage(realSequence, index);
      } else {
        debugPrint("Message with tempId $retryTempId not found");
      }
    } else {
      debugPrint("Sequence not found for tempId: $retryTempId");
    }
  }

  void _handleRetryMessage(int sequence, int index) {
    debugPrint("Sequence: $sequence, Index: $index");

    if (sequence <= 0) {
      debugPrint("Retry message sequence is 0");
      return;
    }

    int userMessageIndex = index - 1;

    while (userMessageIndex >= 0 &&
        _messages[userMessageIndex].message.role != 'user') {
      userMessageIndex--;
    }

    if (userMessageIndex < 0) {
      debugPrint("No user message found to retry");
      return;
    }

    int messagesToRemove = _messages.length - index;

    int historyOffset = _chatHistory.length;
    int count = 0;
    for (int i = _chatHistory.length - 1; i >= 0; i--) {
      if (_chatHistory[i].role == ChatMessageRole.user ||
          _chatHistory[i].role == ChatMessageRole.assistant) {
        count++;
        if (count == messagesToRemove) {
          historyOffset = i;
          break;
        }
      }
    }

    setState(() {
      _messages.removeRange(index, _messages.length);

      if (historyOffset < _chatHistory.length) {
        _chatHistory.removeRange(historyOffset, _chatHistory.length);
      }
    });

    _text = _messages[userMessageIndex].message.content;

    Future.delayed(const Duration(milliseconds: 500), () {
      deleteMessagesInSequence(conversationId, sequence);
    });
    _sendMessage(isRetry: true);
  }

  void _setupChat() {
    _messages.clear();
    _chatHistory.clear();
    _partialResponse = "";
    newLabel = "";
    _sequenceMap.clear();

    _chatHistory.add(
      ChatMessageModel(
        content:
            "Response user in markdown format but not in ``` ``` format excluding the code block.",
        role: ChatMessageRole.system,
      ),
    );

    isNewConversation = ref.read(chatStateProvider).isNewConversation;
    conversationId = ref.read(chatStateProvider).currentConversationId;

    if (isNewConversation) {
      _chatHistory.add(
        ChatMessageModel(
          content: initConversationMsg,
          role: ChatMessageRole.dev,
        ),
      );
    }

    if (!isNewConversation && conversationId.isNotEmpty) {
      _firstLabel = true;
      setState(() {
        _isLoading = true;
      });
      _loadExistingMessages(conversationId);
    } else {
      _firstLabel = false;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadExistingMessages(String conversationId) async {
    try {
      final messages = await getMessages(conversationId);

      setState(() {
        _messages.clear();
        _chatHistory.removeWhere(
          (msg) =>
              msg.role == ChatMessageRole.user ||
              msg.role == ChatMessageRole.assistant,
        );

        for (int i = 0; i < messages.length; i++) {
          final message = messages[i];

          final tempId = 'loaded_${message.sequence}';

          if (message.role == 'user') {
            _messages.add(
              userMessage(
                message.content,
                imageUrls: message.imageUrls,
                tempId: tempId,
              ),
            );
          } else if (message.role == 'assistant') {
            _messages.add(
              assistantMessage(
                message.content,
                true,
                tempId: tempId,
                onRetry: _onRetryTap,
              ),
            );
          }
          _sequenceMap[tempId] = message.sequence;

          _chatHistory.add(
            ChatMessageModel(
              content: message.content,
              role:
                  message.role == 'user'
                      ? ChatMessageRole.user
                      : ChatMessageRole.assistant,
            ),
          );
        }

        _isLoading = false;
      });

      _scrollDown();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint("Error loading messages: $e");
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _isInCodeBlock = false;

  void _sendMessage({bool isRetry = false}) async {
    print("Retry: $isRetry");
    if (_text.trim().isEmpty) return;
    ref.read(chatStateProvider.notifier).setGenerating(true);

    final userMessageText = _text;

    final attachments = ref.read(attachmentUploadsProvider);

    final images =
        attachments
            .where(
              (attachment) =>
                  attachment.status == UploadStatus.completed &&
                  attachment.type == AttachmentType.image,
            )
            .toList();

    final imageUrls = images.map((e) => e.uploadedUrl!).toList();

    final tempUserId = 'temp_user_${_tempMessageCounter++}';
    final tempAssistantId = 'temp_assistant_${_tempMessageCounter++}';

    setState(() {
      if (!isRetry) {
        _messages.add(
          userMessage(
            userMessageText,
            imageUrls: imageUrls,
            tempId: tempUserId,
          ),
        );
      }
      _partialResponse = '';
      _text = "";
    });

    if (!isRetry) {
      if (imageUrls.isNotEmpty) {
        _chatHistory.add(
          ChatMessageModel(
            content: userMessageText,
            role: ChatMessageRole.user,
            imageUrls: imageUrls,
          ),
        );
      } else {
        _chatHistory.add(
          ChatMessageModel(
            content: userMessageText,
            role: ChatMessageRole.user,
          ),
        );
      }
    }

    _scrollDown();

    try {
      setState(() {
        _messages.add(assistantMessage('', false, tempId: tempAssistantId));
      });

      if (conversationId.isEmpty && newLabel.isEmpty) {
        conversationId = await initConversation();
        ref.invalidate(conversationFetch);
      }

      if (conversationId.isNotEmpty) {
        if (!isRetry) {
          createUserMessage(
            content: userMessageText,
            conversationId: conversationId,
            imageUrls: imageUrls,
          ).then((userMsg) {
            _sequenceMap[tempUserId] = userMsg.sequence;
          });
        }
      }

      final messages = _chatHistory.map((msg) => msg.toMap()).toList();

      final chatStream = _openAIService.createChatCompletionStream(
        model: model,
        messages: messages,
        onStop: () async {
          if (_partialResponse.isNotEmpty) {
            final (cleanMessage, _) = extractLabel(_partialResponse);

            if (conversationId.isNotEmpty) {
              createAssistantMessage(
                content: cleanMessage,
                conversationId: conversationId,
              ).then((assistantMsg) {
                _sequenceMap[tempAssistantId] = assistantMsg.sequence;
              });
            }

            _chatHistory.add(
              ChatMessageModel(
                content: "$cleanMessage [STOPPED]",
                role: ChatMessageRole.assistant,
              ),
            );

            setState(() {
              _messages.removeLast();
              _messages.add(
                assistantMessage(
                  cleanMessage,
                  true,
                  tempId: tempAssistantId,

                  onRetry: _onRetryTap,
                ),
              );
            });

            if (!isNewConversation) {
              notifyConversation(conversationId).then((value) {
                ref.invalidate(conversationFetch);
              });
            }
          }
        },
      );

      bool isStreamActive = true;

      chatStream.listen(
        (content) {
          if (!isStreamActive) return;

          setState(() {
            _partialResponse += content;
            final codeBlockCount = _partialResponse.split('```').length - 1;
            _isInCodeBlock = codeBlockCount % 2 == 1;

            final tempResponse =
                _isInCodeBlock ? '$_partialResponse\n```' : _partialResponse;

            final (_, label) = extractLabel(tempResponse);
            if (label != null) {
              newLabel = label;
            }
            _messages.removeLast();
            _messages.add(
              assistantMessage(
                tempResponse,
                false,
                tempId: tempAssistantId,
                onRetry: _onRetryTap,
              ),
            );
          });

          _scrollDown();
        },

        onDone: () {
          isStreamActive = false;

          if (newLabel.isNotEmpty &&
              conversationId.isNotEmpty &&
              !_firstLabel) {
            updateLabel(conversationId, newLabel).then((value) {
              ref.invalidate(conversationFetch);
            });
            _firstLabel = true;
          }

          ref.read(attachmentUploadsProvider.notifier).clearUploads();

          final (cleanMessage, _) = extractLabel(_partialResponse);

          if (conversationId.isNotEmpty) {
            createAssistantMessage(
                  content: cleanMessage,
                  conversationId: conversationId,
                )
                .then((assistantMsg) {
                  _sequenceMap[tempAssistantId] = assistantMsg.sequence;
                })
                .catchError((error) {
                  debugPrint("Error creating assistant message: $error");
                });
          }

          setState(() {
            ref.read(chatStateProvider.notifier).setGenerating(false);
            _chatHistory.add(
              ChatMessageModel(
                content: cleanMessage,
                role: ChatMessageRole.assistant,
              ),
            );
          });

          _messages.removeLast();

          _messages.add(
            assistantMessage(
              cleanMessage,
              true,
              tempId: tempAssistantId,

              onRetry: _onRetryTap,
            ),
          );

          if (!isNewConversation) {
            notifyConversation(conversationId).then((value) {
              ref.invalidate(conversationFetch);
            });
          }
        },

        onError: (error) {
          isStreamActive = false;
          ref.read(chatStateProvider.notifier).setGenerating(false);
          debugPrint("[StreamingError] ${error.toString()}");
          setState(() {
            if (_messages.last.message.content.isEmpty) {
              _messages.removeLast();
            }
          });
          _scrollDown();
        },
      );
    } catch (e) {
      debugPrint("[ChatError] $e");
      setState(() {
        _messages.add(
          ChatMessage(
            message: Message(content: "Error: $e", role: 'assistant'),
          ),
        );
      });
      _scrollDown();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Center(child: CircularProgressIndicator());
    debugPrint("History: ${_chatHistory.length}");

    if (_isLoading == false && _messages.isEmpty) {
      content = EmptyChat();
    }

    if (_isLoading == false && _messages.isNotEmpty) {
      content = ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8.0),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          return _messages[index];
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: ModelSelectionDropdown(
          onModelChanged: (p0) {
            setState(() {
              model = p0;
            });
          },
        ),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.list),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              if (isNewConversation) {
                ref.read(chatStateProvider.notifier).setNewConversation(true);
                ref
                    .read(chatStateProvider.notifier)
                    .setCurrentConversationId('');

                setState(() {
                  _messages.clear();
                  _chatHistory.clear();
                  _partialResponse = "";
                  newLabel = "";
                  _firstLabel = false;
                  _isLoading = false;
                  conversationId = '';
                });
              } else {
                widget.onNew!();
                ref.read(chatStateProvider.notifier).setNewConversation(true);
                ref
                    .read(chatStateProvider.notifier)
                    .setCurrentConversationId('');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: content),
            ChatInput(
              onStopGenerating: () {
                _openAIService.stopStreaming();
                ref.read(chatStateProvider.notifier).setGenerating(false);
              },
              onSendMessage: (text, {attachments}) async {
                _text = text;
                _sendMessage();
              },
            ),
          ],
        ),
      ),
    );
  }
}
