import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/ride.dart';
import '../../services/chat_service.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../util/formatters.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.ride});

  final Ride ride;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final user = Session.require(context);
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    context.read<ChatService>().send(
          rideId: widget.ride.id,
          senderId: user.id,
          senderName: user.name,
          body: text,
        );
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Session.require(context);
    final partnerName = widget.ride.partnerNameFor(user.id);
    final messages = context.watch<ChatService>().messagesFor(widget.ride.id);

    return Scaffold(
      appBar: AppBar(title: Text(partnerName)),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(child: Text('Say hi 👋'))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final m = messages[i];
                      final mine = m.senderId == user.id;
                      return Align(
                        alignment: mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: mine
                                ? AppTheme.harbourTeal
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Column(
                            crossAxisAlignment: mine
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.body,
                                style: TextStyle(
                                  color: mine ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formatDateTime(m.sentAt),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: mine
                                      ? Colors.white70
                                      : Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Message',
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
