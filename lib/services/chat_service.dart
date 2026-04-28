import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';

class ChatService extends ChangeNotifier {
  final Map<String, List<ChatMessage>> _byRide = <String, List<ChatMessage>>{};
  final _uuid = const Uuid();

  List<ChatMessage> messagesFor(String rideId) =>
      List.unmodifiable(_byRide[rideId] ?? const <ChatMessage>[]);

  void send({
    required String rideId,
    required String senderId,
    required String senderName,
    required String body,
  }) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;
    final msg = ChatMessage(
      id: _uuid.v4(),
      rideId: rideId,
      senderId: senderId,
      senderName: senderName,
      body: trimmed,
    );
    _byRide.putIfAbsent(rideId, () => <ChatMessage>[]).add(msg);
    notifyListeners();
  }
}
