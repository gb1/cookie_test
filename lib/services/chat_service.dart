import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_message.dart';
import 'auth_service.dart';

/// Chat is one Postgres table (`chat_messages`) plus a single realtime
/// subscription. We keep an in-memory cache keyed by ride id, hydrated
/// lazily as screens ask for messages.
class ChatService extends ChangeNotifier {
  ChatService({required SupabaseClient client, required AuthService auth})
      : _client = client,
        _auth = auth {
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  final SupabaseClient _client;
  final AuthService _auth;

  final Map<String, List<ChatMessage>> _byRide =
      <String, List<ChatMessage>>{};
  final Set<String> _hydrated = <String>{};
  RealtimeChannel? _channel;

  List<ChatMessage> messagesFor(String rideId) {
    if (!_hydrated.contains(rideId)) {
      _hydrated.add(rideId);
      _hydrate(rideId);
    }
    return List.unmodifiable(_byRide[rideId] ?? const <ChatMessage>[]);
  }

  Future<void> send({
    required String rideId,
    required String senderId,
    required String senderName,
    required String body,
  }) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;
    await _client.from('chat_messages').insert({
      'ride_id': rideId,
      'sender_id': senderId,
      'sender_name': senderName,
      'body': trimmed,
    });
    // Realtime will push it back; UI will update via notifyListeners().
  }

  Future<void> _hydrate(String rideId) async {
    try {
      final rows = await _client
          .from('chat_messages')
          .select()
          .eq('ride_id', rideId)
          .order('sent_at', ascending: true);
      final list = rows.map(_msgFromRow).toList();
      _byRide[rideId] = list;
      notifyListeners();
    } catch (_) {
      // Network blip - the realtime feed will re-populate on next event.
    }
  }

  void _onAuthChanged() {
    final user = _auth.currentUser;
    if (user == null) {
      _disconnect();
      return;
    }
    _connect();
  }

  void _connect() {
    if (_channel != null) return;
    _channel = _client
        .channel('public:chat_messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          callback: (payload) {
            final row = payload.newRecord;
            if (row.isEmpty) return;
            final msg = _msgFromRow(row);
            final list = _byRide.putIfAbsent(
                msg.rideId, () => <ChatMessage>[]);
            if (!list.any((m) => m.id == msg.id)) {
              list.add(msg);
              list.sort((a, b) => a.sentAt.compareTo(b.sentAt));
              notifyListeners();
            }
          },
        )
        .subscribe();
  }

  void _disconnect() {
    if (_channel != null) {
      _client.removeChannel(_channel!);
      _channel = null;
    }
    _byRide.clear();
    _hydrated.clear();
    notifyListeners();
  }

  ChatMessage _msgFromRow(Map<String, dynamic> row) {
    return ChatMessage(
      id: row['id'] as String,
      rideId: row['ride_id'] as String,
      senderId: row['sender_id'] as String,
      senderName: row['sender_name'] as String? ?? 'User',
      body: row['body'] as String? ?? '',
      sentAt: DateTime.parse(row['sent_at'] as String),
    );
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _disconnect();
    super.dispose();
  }
}
