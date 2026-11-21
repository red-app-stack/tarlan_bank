import 'dart:async';
import 'dart:math' show min;
import 'dart:ui';

import 'package:tarlan_bank/models/message.dart';
import 'package:tarlan_bank/core/providers/service_providers.dart';
import 'package:tarlan_bank/services/dio_manager.dart';
import 'package:tarlan_bank/views/other/message_options_sheet.dart';
import 'package:tarlan_bank/views/shared/horizontal_chips.dart';
import 'package:tarlan_bank/views/shared/lamp.dart';
import 'package:tarlan_bank/views/shared/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../services/chat_service.dart';

// ---------------------------------------------------------------------------
// Message model (ValueNotifier-based for fine-grained streaming rebuilds)
// ---------------------------------------------------------------------------

class _ChatMessage {
  final String id;
  final bool isBot;
  final DateTime timestamp;
  final ValueNotifier<String> textNotifier;
  final ValueNotifier<bool> isStreamingNotifier;
  final ValueNotifier<String?> thoughtsNotifier;

  _ChatMessage({
    required this.id,
    required this.isBot,
    required String text,
    bool isStreaming = false,
    String? thoughts,
    required this.timestamp,
  }) : textNotifier = ValueNotifier(text),
       isStreamingNotifier = ValueNotifier(isStreaming),
       thoughtsNotifier = ValueNotifier(thoughts);

  String get text => textNotifier.value;
  set text(String v) => textNotifier.value = v;

  bool get isStreaming => isStreamingNotifier.value;
  set isStreaming(bool v) => isStreamingNotifier.value = v;

  String? get thoughts => thoughtsNotifier.value;
  set thoughts(String? v) => thoughtsNotifier.value = v;

  void dispose() {
    textNotifier.dispose();
    isStreamingNotifier.dispose();
    thoughtsNotifier.dispose();
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
  late AnimationController _headerAnimationController;
  late final ValueNotifier<double> _scrollPosition;
  final List<_ChatMessage> _messages = [];
  final Map<String, AnimationController> _messageAnimations = {};
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ValueNotifier<double> _keyboardHeight;
  late final ValueNotifier<bool> _isProcessingNotifier;
  late final ChatService chat;
  final Uuid _uuid = const Uuid();
  bool _isProcessing = false;
  Timer? _scrollTimer;
  String sessionId = Uuid().v4();
  bool _wasNearBottom = false;

  static const List<String> kquestions = [
    "Когда пришла зарплата?",
    "Когда истекает моя карта?",
    "Сколько осталось выплатить по кредиту?",
    "Сколько процентов по вкладу?",
    "Сколько у меня сейчас на счёте?",
    "Где ближайший банкомат?",
    "Когда платить за интернет?",
    "Как подключить Apple Pay?",
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
  List<String> questions = List.from(kquestions);

  @override
  void initState() {
    super.initState();
    _keyboardHeight = ValueNotifier(0.0);
    _isProcessingNotifier = ValueNotifier(false);
    WidgetsBinding.instance.addObserver(this);

    _scrollPosition = ValueNotifier(0.0);
    _scrollController.addListener(_onScroll);

    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    // _greet();
  }

  Future<void> _greet() async {
    _setProcessing(true);

    await Future.delayed(const Duration(milliseconds: 2000));

    final botMsg = _ChatMessage(
      id: _uuid.v4(),
      isBot: true,
      text: '',
      isStreaming: true,
      timestamp: DateTime.now(),
    );
    _addMessageWithAnimation(botMsg);

    final accumulated = StringBuffer();
    try {
      await chat.sendMessage(
        sessionId: sessionId,
        message: 'Привет!',
        onChunk: (chunk) {
          accumulated.write(chunk);
          _pushChunk(botMsg.id, accumulated.toString());
        },
      );
    } catch (e) {
      debugPrint('_greet error: $e');
    } finally {
      botMsg.isStreaming = false;
      _setProcessing(false);
    }
  }

  Future<void> _clearChat() async {
    await chat.clearSession(sessionId);
    for (final msg in _messages) {
      msg.dispose();
    }
    for (final ctrl in _messageAnimations.values) {
      ctrl.dispose();
    }
    setState(() {
      _messages.clear();
      _messageAnimations.clear();
      questions = List.from(kquestions);
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _scrollTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _textController.dispose();
    _scrollPosition.dispose();
    _keyboardHeight.dispose();
    _isProcessingNotifier.dispose();

    for (final ctrl in _messageAnimations.values) {
      ctrl.dispose();
    }
    for (final msg in _messages) {
      msg.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final maxScrollExtent = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 0.0;
    final currentOffset = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;
    const threshold = 120.0;
    _wasNearBottom = (maxScrollExtent - currentOffset) <= threshold;
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

  void _setProcessing(bool value) {
    _isProcessing = value;
    _isProcessingNotifier.value = value;
    if (mounted) setState(() {});
  }

  void _addMessageWithAnimation(_ChatMessage message) {
    final animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    setState(() {
      _messages.add(message);
      _messageAnimations[message.id] = animationController;
    });

    animationController.forward();
    _scheduleScrollToBottom();
  }

  Future<void> _handleUserMessage(String text) async {
    text = text.trim();
    if (text.isEmpty || _isProcessing) return;

    _addMessageWithAnimation(
      _ChatMessage(
        id: _uuid.v4(),
        isBot: false,
        text: text,
        timestamp: DateTime.now(),
      ),
    );
    _textController.clear();
    _setProcessing(true);

    final botMsg = _ChatMessage(
      id: _uuid.v4(),
      isBot: true,
      text: '',
      isStreaming: true,
      timestamp: DateTime.now(),
    );
    _addMessageWithAnimation(botMsg);

    final accumulated = StringBuffer();
    try {
      await chat.sendMessage(
        sessionId: sessionId,
        message: text,
        onChunk: (chunk) {
          accumulated.write(chunk);
          _pushChunk(botMsg.id, accumulated.toString());
        },
      );
    } catch (e) {
      debugPrint('Ошибка чата: $e');
      if (accumulated.isEmpty) {
        botMsg.text = 'Произошла ошибка. Попробуйте ещё раз.';
      }
    } finally {
      botMsg.isStreaming = false;
      _setProcessing(false);
      _scheduleScrollToBottom();
    }
  }

  void _onScroll() {
    _scrollPosition.value = _scrollController.position.pixels;
    final pos = _scrollController.position;
    _wasNearBottom = (pos.maxScrollExtent - pos.pixels) <= 140;
  }

  void _scheduleScrollToBottom({bool fast = false}) {
    _scrollTimer?.cancel();
    _scrollTimer = Timer(Duration(milliseconds: fast ? 50 : 300), () {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(
          milliseconds: fast ? 150 : (_wasNearBottom ? 400 : 600),
        ),
        curve: Curves.easeOut,
      );
    });
  }

  /// Push a streaming chunk — updates ValueNotifier directly, no setState needed.
  void _pushChunk(String id, String fullText) {
    final idx = _messages.lastIndexWhere((m) => m.id == id);
    if (idx == -1) return;
    _messages[idx].text = fullText;
    _scheduleScrollToBottom(fast: true);
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final double appBarH = kToolbarHeight + 56; // your top padding
    final double chipsH =
        kBottomNavigationBarHeight + 12 + 36 + 8; // input bar + chip rows

    // dimension isn't known here, but MediaQuery gives you the screen width
    // which is usually ≈ dimension on mobile
    final double dim = min(MediaQuery.of(context).size.shortestSide, 800.0);

    return Scaffold(
      appBar: FrostedAppBar(
        floating: true,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/ic_back.svg',
            width: 36,
            height: 36,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.primary,
              BlendMode.srcIn,
            ),
          ),
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'ИИ Консультант',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/trash.svg',
              width: 32,
              height: 32,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.primary,
                BlendMode.srcIn,
              ),
            ),
            onPressed: () {
              _clearChat();
            },
          ),
        ],
      ),
      extendBody: true,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      // floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // floatingActionButton: _messages.length <= 1
      //     ? SafeOffsetFab(
      //         offsetY: 180,
      //         child: FloatingActionButton(
      //           onPressed: () {},
      //           backgroundColor: theme.colorScheme.primary,
      //           child: SvgPicture.asset(
      //             'assets/icons/ic_support.svg',
      //             width: 36,
      //             height: 36,
      //             colorFilter: const ColorFilter.mode(
      //               Color(0xFFF5F5F5),
      //               BlendMode.srcIn,
      //             ),
      //           ),
      //         ),
      //       )
      //     : null,
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Stack(
              children: [
                // Chat content — fills the whole body, scrolls UNDER the frosted bar.
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: kBottomNavigationBarHeight + 12,
                  ),
                  child: Column(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 600),
                        transitionBuilder: (child, animation) => SizeTransition(
                          sizeFactor: animation,
                          child: FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOut,
                              ),
                              child: child,
                            ),
                          ),
                        ),
                        child: _messages.isEmpty
                            ? Center(
                                child: LavaLampMetaBalls(key: ValueKey('lava')),
                              )
                            : const SizedBox(key: ValueKey('empty')),
                      ),
                      Expanded(
                        child: NotificationListener<ScrollUpdateNotification>(
                          onNotification: (_) {
                            _wasNearBottom =
                                _scrollController.hasClients &&
                                (_scrollController.position.maxScrollExtent -
                                        _scrollController.offset) <=
                                    140;
                            return false;
                          },
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final animCtrl = _messageAnimations[message.id];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: _AnimatedBubble(
                                  key: ValueKey(message.id),
                                  message: message,
                                  entranceAnim: animCtrl,
                                  onLongPress: () {
                                    HapticFeedback.mediumImpact();
                                    showModalBottomSheet(
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
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Frosted input bar — floats on top, pinned to the bottom.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildInputBar(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cs.background.withValues(alpha: .35),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                transitionBuilder: (child, animation) => SizeTransition(
                  sizeFactor: animation,
                  child: FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      ),
                      child: child,
                    ),
                  ),
                ),
                child: _messages.length <= 10
                    ? HorizontalExamples(
                        key: const ValueKey('prompts'),
                        questions: questions,
                        onSelected: (question) {
                          _handleUserMessage(question);
                          setState(() => questions.remove(question));
                        },
                      )
                    : const SizedBox(key: ValueKey('emptyexamples')),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: ValueListenableBuilder<bool>(
                  valueListenable: _isProcessingNotifier,
                  builder: (_, processing, _) => Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainer,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(30),
                            ),
                          ),
                          child: TextField(
                            controller: _textController,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (v) => _handleUserMessage(v),
                            enabled: !processing,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              filled: false,
                              hintText: processing
                                  ? 'Ожидание ответа...'
                                  : 'Задайте интересующий вопрос',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: processing
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    cs.primary,
                                  ),
                                ),
                              )
                            : SvgPicture.asset(
                                'assets/icons/ic_send.svg',
                                width: 28,
                                height: 28,
                                colorFilter: ColorFilter.mode(
                                  cs.primary,
                                  BlendMode.srcIn,
                                ),
                              ),
                        onPressed: processing
                            ? null
                            : () => _handleUserMessage(_textController.text),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animated bubble wrapper (entrance animation)
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
    return bubble;
  }
}

// ---------------------------------------------------------------------------
// Message bubble
// ---------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final VoidCallback? onLongPress;

  const _MessageBubble({required this.message, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final isBot = message.isBot;

    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isBot ? cs.surfaceContainer : cs.primary,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isBot ? 4 : 16),
                bottomRight: Radius.circular(isBot ? 16 : 4),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thoughts expansion (bot only)
                if (isBot)
                  ValueListenableBuilder<String?>(
                    valueListenable: message.thoughtsNotifier,
                    builder: (_, thoughts, _) {
                      if (thoughts == null || thoughts.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return _ThoughtsExpansion(
                        theme: theme,
                        thoughts: thoughts,
                      );
                    },
                  ),
                // Message content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: isBot
                          ? ValueListenableBuilder<bool>(
                              valueListenable: message.isStreamingNotifier,
                              builder: (ctx, streaming, _) =>
                                  ValueListenableBuilder<String>(
                                    valueListenable: message.textNotifier,
                                    builder: (ctx2, text, _) {
                                      if (text.isEmpty) {
                                        return const SizedBox(
                                          width: 4,
                                          height: 0,
                                        );
                                      }
                                      return _BotRichText(
                                        text: text,
                                        cs: cs,
                                        tt: tt,
                                        isStreaming: streaming,
                                      );
                                    },
                                  ),
                            )
                          : ValueListenableBuilder<String>(
                              valueListenable: message.textNotifier,
                              builder: (_, text, _) => Text(
                                text,
                                style: TextStyle(
                                  color: cs.onPrimary,
                                  fontSize: 13,
                                  fontFamily: 'OpenSans',
                                  height: 1.45,
                                ),
                              ),
                            ),
                    ),
                    if (isBot)
                      ValueListenableBuilder<bool>(
                        valueListenable: message.isStreamingNotifier,
                        builder: (_, streaming, _) {
                          final showDots = streaming && message.text.isEmpty;
                          return AnimatedSize(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                            child: AnimatedOpacity(
                              opacity: showDots ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                              child: showDots
                                  ? const Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: _TypingDots(),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Thoughts expansion tile (unchanged layout from original)
// ---------------------------------------------------------------------------

class _ThoughtsExpansion extends StatelessWidget {
  final ThemeData theme;
  final String thoughts;
  const _ThoughtsExpansion({required this.theme, required this.thoughts});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        dense: true,
        title: Text(
          'Размышления',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            child: Text(
              thoughts,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animated typing dots (improved from new file)
// ---------------------------------------------------------------------------

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
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
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _ctrl,
            builder: (_, _) {
              final phase = (_ctrl.value - i * 0.08).clamp(0.0, 1.0);
              final scale =
                  0.6 + 0.5 * (1 - (phase - 0.4).abs() * 3).clamp(0.0, 1.0);
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
// Markdown renderer (_BotRichText) — ported from new file, no nav dependency
// ---------------------------------------------------------------------------

enum _BlockType { paragraph, bullet, code, heading, divider }

class _Block {
  final _BlockType type;
  final String content;
  final int level;
  const _Block._(this.type, this.content, {this.level = 0});
  const _Block.paragraph(String c) : this._(_BlockType.paragraph, c);
  const _Block.bullet(String c) : this._(_BlockType.bullet, c);
  const _Block.code(String c) : this._(_BlockType.code, c);
  const _Block.heading(String c, int lvl)
    : this._(_BlockType.heading, c, level: lvl);
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
    bool inCodeFence = false;

    void flushBuffer() {
      final s = buffer.toString().trim();
      if (s.isNotEmpty) blocks.add(_Block.paragraph(s));
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
      final numMatch = RegExp(r'^\d+\.\s+(.+)').firstMatch(trimmed);
      if (numMatch != null) {
        flushBuffer();
        blocks.add(_Block.bullet(numMatch.group(1)!));
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
    final re = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|`(.+?)`|([^*`]+)');
    for (final m in re.allMatches(line)) {
      if (m.group(1) != null) {
        spans.add(
          TextSpan(
            text: m.group(1),
            style: base.copyWith(fontWeight: FontWeight.w700),
          ),
        );
      } else if (m.group(2) != null) {
        spans.add(
          TextSpan(
            text: m.group(2),
            style: base.copyWith(fontStyle: FontStyle.italic),
          ),
        );
      } else if (m.group(3) != null) {
        spans.add(
          TextSpan(
            text: m.group(3),
            style: base.copyWith(
              fontFamily: 'monospace',
              backgroundColor: widget.cs.surfaceContainerHighest,
              fontSize: (base.fontSize ?? 14) * 0.92,
            ),
          ),
        );
      } else if (m.group(4) != null) {
        spans.add(TextSpan(text: m.group(4), style: base));
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

    final base = const TextStyle().copyWith(
      color: widget.cs.onSurface,
      fontSize: 14,
      fontFamily: 'OpenSans',
      height: 1.45,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < _cachedBlocks.length; i++) ...[
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
              : (base.fontSize ?? 14) * 1.00,
          height: 1.45,
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
