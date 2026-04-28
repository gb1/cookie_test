import 'dart:convert';

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.rideId,
    required this.senderId,
    required this.senderName,
    required this.body,
    DateTime? sentAt,
  }) : sentAt = sentAt ?? DateTime.now();

  final String id;
  final String rideId;
  final String senderId;
  final String senderName;
  final String body;
  final DateTime sentAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'rideId': rideId,
        'senderId': senderId,
        'senderName': senderName,
        'body': body,
        'sentAt': sentAt.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as String,
        rideId: j['rideId'] as String,
        senderId: j['senderId'] as String,
        senderName: j['senderName'] as String,
        body: j['body'] as String,
        sentAt: DateTime.parse(j['sentAt'] as String),
      );

  static String encodeList(List<ChatMessage> ms) =>
      jsonEncode(ms.map((m) => m.toJson()).toList());

  static List<ChatMessage> decodeList(String s) =>
      (jsonDecode(s) as List)
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList();
}
