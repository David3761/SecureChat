class TextMessagePayload {
  final String content;
  final DateTime timestamp;

  TextMessagePayload({required this.content, required this.timestamp});

  Map<String, dynamic> toJson() => {
    'type': 'text',
    'content': content,
    'timestamp': timestamp.toIso8601String(),
  };

  factory TextMessagePayload.fromJson(Map<String, dynamic> json) {
    final ts = json['timestamp'] as String?;
    return TextMessagePayload(
      content: json['content'] as String,
      timestamp: ts != null ? DateTime.parse(ts) : DateTime.now(),
    );
  }
}
