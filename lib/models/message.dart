class Message {
  final String id;
  String text;
  final bool isBot;
  final DateTime timestamp;
  bool isStreaming;
  String? thoughts;

  Message({
    required this.id,
    required this.text,
    required this.isBot,
    required this.timestamp,
    this.isStreaming = false,
    this.thoughts,
  });

  Message copyWith({String? text, bool? isStreaming, String? thoughts}) {
    return Message(
      id: id,
      text: text ?? this.text,
      isBot: isBot,
      timestamp: timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      thoughts: thoughts ?? this.thoughts,
    );
  }
}
