import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tarlan_bank/core/providers/service_providers.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/models/message.dart';
import 'package:tarlan_bank/views/other/message_options_sheet.dart';
import 'package:tarlan_bank/views/shared/widgets.dart';
import 'package:uuid/uuid.dart';

import 'package:tarlan_bank/services/chat_service.dart';

// ---------------------------------------------------------------------------
// Chat icons — copied from the kitaphub chat feature.
// ---------------------------------------------------------------------------
const String _iconChatbot = 'assets/icons/chat/chatbot.svg';
const String _iconChatBubble = 'assets/icons/chat/chat_bubble.svg';
const String _iconSend = 'assets/icons/chat/send.svg';
const String _iconRestart = 'assets/icons/chat/restart_square.svg';

Widget _appIcon(String path, {double size = 24, Color? color, Key? key}) {
  return SvgPicture.asset(
    path,
    key: key,
    width: size,
    height: size,
    colorFilter: color != null
        ? ColorFilter.mode(color, BlendMode.srcIn)
        : null,
  );
}

// ---------------------------------------------------------------------------
// Message model (ValueNotifier-based for fine-grained streaming rebuilds).
// ---------------------------------------------------------------------------
class _ChatMessage {
  final String id;
  final bool isBot;
  final DateTime timestamp;
  final ValueNotifier<String> textNotifier;
  final ValueNotifier<bool> isStreamingNotifier;

  _ChatMessage({
    required this.id,
    required this.isBot,
    required String text,
    bool isStreaming = false,
    required this.timestamp,
  }) : textNotifier = ValueNotifier(text),
       isStreamingNotifier = ValueNotifier(isStreaming);

  String get text => textNotifier.value;
  set text(String value) => textNotifier.value = value;

  bool get isStreaming => isStreamingNotifier.value;
  set isStreaming(bool value) => isStreamingNotifier.value = value;

  void dispose() {
    textNotifier.dispose();
    isStreamingNotifier.dispose();
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class ChatBotScreen extends ConsumerStatefulWidget {
  const ChatBotScreen({super.key});

  @override
  ConsumerState<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends ConsumerState<ChatBotScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final List<_ChatMessage> _messages = [];
  final Map<String, AnimationController> _messageAnimations = {};
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final Uuid _uuid = const Uuid();
  late final ValueNotifier<double> _keyboardHeight;
  late final ValueNotifier<bool> _isProcessingNotifier;
  late final ChatService chat;
  late final String _sessionId;
  Timer? _scrollTimer;
  bool _wasNearBottom = false;
  String? _streamingMessageId;
  late final AnimationController _headerAnimationController;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  /// The bank's example questions. Kept verbatim — only their presentation
  /// (a horizontally auto-scrolling row of chips) was reworked.
  static const List<String> kquestions = [
    'Когда пришла зарплата?',
    'Когда истекает моя карта?',
    'Сколько осталось выплатить по кредиту?',
    'Сколько процентов по вкладу?',
    'Сколько у меня сейчас на счёте?',
    'Где ближайший банкомат?',
    'Когда платить за интернет?',
    'Как подключить Apple Pay?',
    'Как изменить лимит по карте?',
    'Как подключить SMS-уведомления?',
    'Как сменить ПИН-код карты?',
    'Могу ли я заказать новую карту онлайн?',
    'Как открыть вклад на 6 месяцев?',
    'Какие комиссии за переводы?',
    'Как перевести деньги между своими счетами?',
    'Как заблокировать карту при потере?',
    'Как изменить адрес электронной почты или телефон?',
    'Есть ли бонусы за покупки по карте?',
  ];

  List<String> _remainingSuggestions = List<String>.from(kquestions);

  @override
  void initState() {
    super.initState();
    chat = ChatService(dio: ref.read(dioManagerProvider));
    _sessionId = _uuid.v4();
    _keyboardHeight = ValueNotifier(0.0);
    _isProcessingNotifier = ValueNotifier(false);
    WidgetsBinding.instance.addObserver(this);

    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    final sharedCurve = CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOut,
    );
    _headerFade = sharedCurve;
    _headerSlide = Tween<Offset>(
      begin: const Offset(0.0, 1),
      end: const Offset(0.0, 0.7),
    ).animate(sharedCurve);
    _headerAnimationController.forward();

    // Kitaphub warms the session up on entry without showing a greeting
    // bubble, so the empty state and the suggestion row stay visible.
    _warmup();
  }

  Future<void> _warmup() async {
    try {
      await chat.warmup();
    } catch (e) {
      debugPrint('ChatBotScreen: warmup skipped — $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollTimer?.cancel();
    _headerAnimationController.dispose();
    for (final controller in _messageAnimations.values) {
      controller.dispose();
    }
    for (final message in _messages) {
      message.dispose();
    }
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _keyboardHeight.dispose();
    _isProcessingNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _checkNearBottom();
    super.didChangeMetrics();
    _updateKeyboardHeight();
    if (_keyboardHeight.value > 0 && _wasNearBottom) {
      _scheduleScrollToBottom();
    }
  }

  void _updateKeyboardHeight() {
    if (!mounted) return;
    _keyboardHeight.value = MediaQueryData.fromView(View.of(context))
        .viewInsets
        .bottom;
  }

  void _checkNearBottom() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    _wasNearBottom = (position.maxScrollExtent - position.pixels) <= 140;
  }

  void _setProcessing(bool value) {
    _isProcessingNotifier.value = value;
    if (mounted) setState(() {});
  }

  AnimationController _makeEntranceAnimation() {
    return AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..forward();
  }

  void _addMessage(_ChatMessage message) {
    final controller = _makeEntranceAnimation();
    setState(() {
      _messages.add(message);
      _messageAnimations[message.id] = controller;
    });
    _scheduleScrollToBottom();
  }

  /// Push a streaming chunk — updates the ValueNotifier directly.
  void _pushChunk(String id, String fullText) {
    final index = _messages.lastIndexWhere((message) => message.id == id);
    if (index == -1) return;
    _messages[index].text = fullText;
    _scheduleScrollToBottom(fast: true);
  }

  void _finalizeMessage(String id) {
    final index = _messages.lastIndexWhere((message) => message.id == id);
    if (index == -1) return;
    _messages[index].isStreaming = false;
  }

  Future<void> _handleSend(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || _isProcessingNotifier.value) return;

    final l = AppLocalizations.of(context);
    _textController.clear();
    _setProcessing(true);
    _addMessage(
      _ChatMessage(
        id: _uuid.v4(),
        isBot: false,
        text: text,
        timestamp: DateTime.now(),
      ),
    );

    final botMessage = _ChatMessage(
      id: _uuid.v4(),
      isBot: true,
      text: '',
      isStreaming: true,
      timestamp: DateTime.now(),
    );
    _streamingMessageId = botMessage.id;
    _addMessage(botMessage);

    final accumulated = StringBuffer();
    try {
      await chat.sendMessage(
        sessionId: _sessionId,
        message: text,
        onChunk: (chunk) {
          accumulated.write(chunk);
          final id = _streamingMessageId;
          if (id != null) _pushChunk(id, accumulated.toString());
        },
      );
      final id = _streamingMessageId;
      if (id != null) _finalizeMessage(id);
    } catch (e) {
      final id = _streamingMessageId;
      if (id != null) {
        _pushChunk(
          id,
          accumulated.isEmpty ? l.chatErrorResponse : accumulated.toString(),
        );
        _finalizeMessage(id);
      }
      debugPrint('ChatBotScreen: send failed — $e');
    } finally {
      _streamingMessageId = null;
      _setProcessing(false);
      _scheduleScrollToBottom();
    }
  }

  void _scheduleScrollToBottom({bool fast = false}) {
    _scrollTimer?.cancel();
    _scrollTimer = Timer(Duration(milliseconds: fast ? 50 : 200), () {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: fast ? 150 : 380),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _clearChat() async {
    await chat.clearSession(_sessionId);
    for (final message in _messages) {
      message.dispose();
    }
    for (final controller in _messageAnimations.values) {
      controller.dispose();
    }
    setState(() {
      _messages.clear();
      _messageAnimations.clear();
      _remainingSuggestions = List<String>.from(kquestions);
    });
    _headerAnimationController.forward(from: 0);
  }

  void _onLongPressMessage(_ChatMessage message) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => MessageOptionsSheet(
        message: Message(
          id: message.id,
          text: message.text,
          isBot: message.isBot,
          timestamp: message.timestamp,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(cs, tt, l),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeInOut,
                  child: _messages.isEmpty
                      ? SlideTransition(
                          position: _headerSlide,
                          child: _EmptyChatState(
                            fade: _headerFade,
                            title: l.chatEmptyTitle,
                            subtitle: l.chatEmptySubtitle,
                            greeting: l.chatGreeting,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  child: NotificationListener<ScrollUpdateNotification>(
                    onNotification: (notification) {
                      _checkNearBottom();
                      return false;
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        kToolbarHeight + 56,
                        16,
                        92,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _AnimatedBubble(
                          key: ValueKey(message.id),
                          message: message,
                          entranceAnim: _messageAnimations[message.id],
                          onLongPress: () => _onLongPressMessage(message),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: MediaQuery.of(context).padding.bottom + 4,
              child: _buildInputArea(cs, tt, l),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    ColorScheme cs,
    TextTheme tt,
    AppLocalizations l,
  ) {
    return FrostedAppBar(
      leading: IconButton(
        icon: SvgPicture.asset(
          'assets/icons/ic_back.svg',
          width: 36,
          height: 36,
          colorFilter: ColorFilter.mode(cs.primary, BlendMode.srcIn),
        ),
        onPressed: () {
          FocusScope.of(context).unfocus();
          Navigator.of(context).pop();
        },
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: l.chatGreeting,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: _appIcon(_iconChatBubble, size: 18, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.chatBotName,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: _isProcessingNotifier,
                builder: (_, processing, _) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    processing ? l.chatBotThinking : l.chatBotSubtitle,
                    key: ValueKey(processing),
                    style: tt.labelSmall?.copyWith(
                      color: processing ? cs.primary : cs.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: l.chatClearConversation,
          icon: _appIcon(_iconRestart, size: 22, color: cs.primary),
          onPressed: _messages.isEmpty ? null : _clearChat,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildInputArea(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    return Column(
      spacing: 32,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          child: _remainingSuggestions.isNotEmpty && _messages.isEmpty
              ? _SuggestionChips(
                  key: ValueKey(_remainingSuggestions.length),
                  questions: _remainingSuggestions,
                  onSelected: (question) {
                    if (_isProcessingNotifier.value) return;
                    setState(() => _remainingSuggestions.remove(question));
                    _handleSend(question);
                  },
                )
              : const SizedBox.shrink(),
        ),
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cs.surface.withValues(alpha: 0.82),
                border: Border(
                  top: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.7),
                  ),
                  left: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.7),
                  ),
                  right: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.7),
                  ),
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: ValueListenableBuilder<bool>(
                  valueListenable: _isProcessingNotifier,
                  builder: (_, processing, _) => Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _InputField(
                          controller: _textController,
                          focusNode: _focusNode,
                          enabled: !processing,
                          onSubmitted: _handleSend,
                          hint: processing
                              ? l.chatInputHintThinking
                              : l.chatInputHint,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _SendButton(
                        isProcessing: processing,
                        onPressed: () => _handleSend(_textController.text),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state — kitaphub's icon-first layout with bank/support wording.
// ---------------------------------------------------------------------------
class _EmptyChatState extends StatelessWidget {
  final Animation<double> fade;
  final String title;
  final String subtitle;
  final String greeting;

  const _EmptyChatState({
    required this.fade,
    required this.title,
    required this.subtitle,
    required this.greeting,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return FadeTransition(
      opacity: fade,
      child: Semantics(
        label: greeting,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.primaryContainer.withValues(alpha: 0.45),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: SvgPicture.asset(_iconChatbot),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scrollable suggestion questions (kitaphub behaviour, bank questions).
// ---------------------------------------------------------------------------
class _SuggestionChips extends StatefulWidget {
  final List<String> questions;
  final ValueChanged<String> onSelected;

  const _SuggestionChips({
    super.key,
    required this.questions,
    required this.onSelected,
  });

  @override
  State<_SuggestionChips> createState() => _SuggestionChipsState();
}

class _SuggestionChipsState extends State<_SuggestionChips> {
  late final ScrollController _scrollController;
  Timer? _autoScrollTimer;
  bool _userScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (!mounted || _userScrolling || !_scrollController.hasClients) return;
      final position = _scrollController.position;
      if (position.pixels >= position.maxScrollExtent) {
        _scrollController.jumpTo(0);
      } else {
        _scrollController.jumpTo(position.pixels + 1.2);
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return SizedBox(
      height: 44,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification &&
              notification.dragDetails != null) {
            _userScrolling = true;
          } else if (notification is ScrollEndNotification) {
            Future<void>.delayed(const Duration(seconds: 2), () {
              if (mounted) _userScrolling = false;
            });
          }
          return false;
        },
        child: ListView.separated(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          itemCount: widget.questions.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, index) {
            final question = widget.questions[index];
            return GestureDetector(
              onTap: () => widget.onSelected(question),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(
                    question,
                    style: tt.labelMedium?.copyWith(
                      color: cs.onSecondaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Input field and send button (kitaphub style).
// ---------------------------------------------------------------------------
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final ValueChanged<String> onSubmitted;
  final String hint;

  const _InputField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSubmitted,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      maxLines: 4,
      minLines: 1,
      textInputAction: TextInputAction.send,
      onSubmitted: onSubmitted,
      textAlignVertical: TextAlignVertical.center,
      style: tt.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: tt.bodyMedium?.copyWith(
          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, right: 4),
          child: Center(
            widthFactor: 1.0,
            heightFactor: 1.0,
            child: _appIcon(
              _iconChatBubble,
              size: 20,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(maxWidth: 36),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 12,
        ),
        isDense: false,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: cs.primary.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.7),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback onPressed;

  const _SendButton({required this.isProcessing, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isProcessing ? cs.onSurface.withValues(alpha: 0.10) : cs.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isProcessing
            ? const []
            : [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.30),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: isProcessing ? null : onPressed,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: isProcessing
                  ? SizedBox.square(
                      key: const ValueKey('loader'),
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onSurfaceVariant,
                      ),
                    )
                  : _appIcon(
                      _iconSend,
                      key: const ValueKey('send'),
                      size: 20,
                      color: cs.onPrimary,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bubbles
// ---------------------------------------------------------------------------
class _AnimatedBubble extends StatelessWidget {
  final _ChatMessage message;
  final AnimationController? entranceAnim;
  final VoidCallback? onLongPress;

  const _AnimatedBubble({
    super.key,
    required this.message,
    this.entranceAnim,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    Widget bubble = _MessageBubble(message: message, onLongPress: onLongPress);
    if (entranceAnim != null) {
      bubble = FadeTransition(
        opacity: CurvedAnimation(parent: entranceAnim!, curve: Curves.easeOut),
        child: SlideTransition(
          position:
              Tween<Offset>(
                begin: Offset(message.isBot ? -0.06 : 0.06, 0.04),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: entranceAnim!,
                  curve: Curves.easeOutCubic,
                ),
              ),
          child: bubble,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: bubble,
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final VoidCallback? onLongPress;

  const _MessageBubble({required this.message, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isBot = message.isBot;
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.80,
          ),
          child: Column(
            crossAxisAlignment: isBot
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isBot ? cs.surfaceContainerHigh : cs.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isBot ? 4 : 18),
                    bottomRight: Radius.circular(isBot ? 18 : 4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isBot ? cs.shadow : cs.primary).withValues(
                        alpha: 0.08,
                      ),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: isBot
                          ? ValueListenableBuilder<bool>(
                              valueListenable: message.isStreamingNotifier,
                              builder: (_, streaming, _) {
                                return ValueListenableBuilder<String>(
                                  valueListenable: message.textNotifier,
                                  builder: (_, text, _) {
                                    if (text.isEmpty) {
                                      return const SizedBox(
                                        width: 4,
                                        height: 20,
                                      );
                                    }
                                    return _BotRichText(
                                      text: text,
                                      cs: cs,
                                      tt: tt,
                                      isStreaming: streaming,
                                    );
                                  },
                                );
                              },
                            )
                          : ValueListenableBuilder<String>(
                              valueListenable: message.textNotifier,
                              builder: (_, text, _) => Text(
                                text,
                                style: tt.bodyMedium?.copyWith(
                                  color: cs.onPrimary,
                                  height: 1.45,
                                ),
                              ),
                            ),
                    ),
                    if (isBot)
                      ValueListenableBuilder<bool>(
                        valueListenable: message.isStreamingNotifier,
                        builder: (_, streaming, _) {
                          if (!streaming) return const SizedBox.shrink();
                          return const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: _TypingDots(),
                          );
                        },
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                child: Text(
                  _formatTime(message.timestamp),
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTime(DateTime time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 28,
      height: 14,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (_, _) {
              final phase = (_controller.value - index * 0.18).clamp(0.0, 1.0);
              final scale =
                  0.5 + 0.5 * (1 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lightweight markdown renderer for streaming bot replies.
// ---------------------------------------------------------------------------
enum _BlockType { paragraph, bullet, code, heading, divider }

class _Block {
  final _BlockType type;
  final String content;
  final int level;

  const _Block._(this.type, this.content, {this.level = 0});
  const _Block.paragraph(String content)
    : this._(_BlockType.paragraph, content);
  const _Block.bullet(String content) : this._(_BlockType.bullet, content);
  const _Block.code(String content) : this._(_BlockType.code, content);
  const _Block.heading(String content, int level)
    : this._(_BlockType.heading, content, level: level);
  const _Block.divider() : this._(_BlockType.divider, '');
}

class _BotRichText extends StatefulWidget {
  final String text;
  final ColorScheme cs;
  final TextTheme tt;
  final bool isStreaming;

  const _BotRichText({
    required this.text,
    required this.cs,
    required this.tt,
    required this.isStreaming,
  });

  @override
  State<_BotRichText> createState() => _BotRichTextState();
}

class _BotRichTextState extends State<_BotRichText> {
  String _lastText = '';
  List<_Block> _cachedBlocks = [];

  List<_Block> _parseBlocks(String raw) {
    final blocks = <_Block>[];
    final lines = raw.split('\n');
    final buffer = StringBuffer();
    var inCodeFence = false;

    void flushBuffer() {
      final text = buffer.toString().trim();
      if (text.isNotEmpty) blocks.add(_Block.paragraph(text));
      buffer.clear();
    }

    for (final line in lines) {
      if (line.trimLeft().startsWith('```')) {
        if (inCodeFence) {
          blocks.add(_Block.code(buffer.toString()));
          buffer.clear();
          inCodeFence = false;
        } else {
          flushBuffer();
          inCodeFence = true;
        }
        continue;
      }
      if (inCodeFence) {
        if (buffer.isNotEmpty) buffer.writeln();
        buffer.write(line);
        continue;
      }
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        flushBuffer();
        continue;
      }
      if (RegExp(r'^[-*_]{3,}$').hasMatch(trimmed)) {
        flushBuffer();
        blocks.add(const _Block.divider());
        continue;
      }
      final headingMatch = RegExp(r'^(#{1,3})\s+(.+)$').firstMatch(trimmed);
      if (headingMatch != null) {
        flushBuffer();
        final level = headingMatch.group(1)!.length;
        final content = headingMatch
            .group(2)!
            .replaceAll(RegExp(r'\s+#+\s*$'), '')
            .trim();
        blocks.add(_Block.heading(content, level));
        continue;
      }
      if (RegExp(r'^[-*•]\s').hasMatch(trimmed)) {
        flushBuffer();
        blocks.add(_Block.bullet(trimmed.substring(2).trim()));
        continue;
      }
      final numbered = RegExp(r'^\d+\.\s+(.+)').firstMatch(trimmed);
      if (numbered != null) {
        flushBuffer();
        blocks.add(_Block.bullet(numbered.group(1)!));
        continue;
      }
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(trimmed);
    }
    if (inCodeFence) {
      blocks.add(_Block.code(buffer.toString()));
    } else {
      flushBuffer();
    }
    return blocks;
  }

  List<InlineSpan> _parseInline(String line, TextStyle base) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|`(.+?)`|([^*`]+)');
    for (final match in regex.allMatches(line)) {
      if (match.group(1) != null) {
        spans.add(
          TextSpan(
            text: match.group(1),
            style: base.copyWith(fontWeight: FontWeight.w700),
          ),
        );
      } else if (match.group(2) != null) {
        spans.add(
          TextSpan(
            text: match.group(2),
            style: base.copyWith(fontStyle: FontStyle.italic),
          ),
        );
      } else if (match.group(3) != null) {
        spans.add(
          TextSpan(
            text: match.group(3),
            style: base.copyWith(
              fontFamily: 'monospace',
              backgroundColor: widget.cs.surfaceContainerHighest,
              fontSize: (base.fontSize ?? 14) * 0.92,
            ),
          ),
        );
      } else if (match.group(4) != null) {
        spans.add(TextSpan(text: match.group(4), style: base));
      }
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.text != _lastText) {
      _lastText = widget.text;
      _cachedBlocks = _parseBlocks(_lastText);
    }
    final base = (widget.tt.bodyMedium ?? const TextStyle()).copyWith(
      color: widget.cs.onSurface,
      height: 1.45,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _cachedBlocks.length; i++) ...[
          if (i > 0) SizedBox(height: _blockSpacing(_cachedBlocks[i])),
          _buildBlock(_cachedBlocks[i], base),
        ],
      ],
    );
  }

  double _blockSpacing(_Block block) {
    switch (block.type) {
      case _BlockType.heading:
        return 10;
      case _BlockType.divider:
        return 8;
      default:
        return 5;
    }
  }

  Widget _buildBlock(_Block block, TextStyle base) {
    switch (block.type) {
      case _BlockType.heading:
        final headingStyle = base.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: block.level == 1
              ? (base.fontSize ?? 14) * 1.22
              : block.level == 2
              ? (base.fontSize ?? 14) * 1.10
              : (base.fontSize ?? 14),
          height: 1.3,
        );
        return Padding(
          padding: EdgeInsets.only(top: block.level <= 2 ? 4 : 2),
          child: RichText(
            text: TextSpan(children: _parseInline(block.content, headingStyle)),
          ),
        );
      case _BlockType.divider:
        return Divider(
          color: widget.cs.outlineVariant.withValues(alpha: 0.5),
          thickness: 1,
          height: 16,
        );
      case _BlockType.code:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            block.content,
            style: base.copyWith(
              fontFamily: 'monospace',
              fontSize: (base.fontSize ?? 14) * 0.90,
            ),
          ),
        );
      case _BlockType.bullet:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 7, right: 8),
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: widget.cs.onSurface.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Flexible(
              child: RichText(
                text: TextSpan(children: _parseInline(block.content, base)),
              ),
            ),
          ],
        );
      case _BlockType.paragraph:
        return RichText(
          text: TextSpan(children: _parseInline(block.content, base)),
        );
    }
  }
}
