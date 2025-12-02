import 'package:riverpod/riverpod.dart';

class ChatState {
  final bool isGenerating;
  final bool isHasImage;
  final List<String> images;

  final String currentConversationId;
  final bool isNewConversation;

  const ChatState({
    this.isGenerating = false,
    this.isHasImage = false,
    this.images = const [],
    this.isNewConversation = true,
    this.currentConversationId = '',
  });

  ChatState.blank()
    : isGenerating = false,
      isHasImage = false,
      images = [],
      isNewConversation = true,
      currentConversationId = '';

  ChatState copyWith({
    bool? isGenerating,
    bool? isHasImage,
    List<String>? images,
    String? currentConversationId,
    bool? isNewConversation,
  }) {
    return ChatState(
      currentConversationId:
          currentConversationId ?? this.currentConversationId,
      isGenerating: isGenerating ?? this.isGenerating,
      isHasImage: isHasImage ?? this.isHasImage,
      images: images ?? this.images,
      isNewConversation: isNewConversation ?? this.isNewConversation,
    );
  }
}

class ChatStateNotifer extends StateNotifier<ChatState> {
  ChatStateNotifer() : super(ChatState.blank());

  void setGenerating(bool isGenerating) {
    state = state.copyWith(isGenerating: isGenerating);
  }

  void setHasImage(bool isHasImage) {
    state = state.copyWith(isHasImage: isHasImage);
  }

  void addImage(String image) {
    state = state.copyWith(images: [...state.images, image]);
  }

  void clearImages() {
    state = state.copyWith(images: []);
  }

  void setCurrentConversationId(String conversationId) {
    state = state.copyWith(currentConversationId: conversationId);
  }

  void setNewConversation(bool isNewConversation) {
    state = state.copyWith(isNewConversation: isNewConversation);
  }
}

final chatStateProvider = StateNotifierProvider<ChatStateNotifer, ChatState>((
  ref,
) {
  return ChatStateNotifer();
});
