import 'package:eventmanager/models/contact.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/chat/chat_bloc.dart';
import '../../models/chat_message.dart';

class ChatScreen extends StatelessWidget {
  final Contact contact;
  const ChatScreen({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view messages')),
      );
    }

    return BlocProvider(
      create:
          (context) =>
              ChatBloc(authState.user.uid)
                ..add(LoadMessagesForContact(contact.uid)),
      child: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is ChatLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ChatLoaded) {
            return Scaffold(
              appBar: AppBar(
                title: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage:
                          contact.photoUrl != null
                              ? NetworkImage(contact.photoUrl!)
                              : null,
                      child:
                          contact.photoUrl == null
                              ? Text(contact.name[0].toUpperCase())
                              : null,
                    ),
                    const SizedBox(width: 12),
                    Text(contact.name),
                  ],
                ),
              ),
              body: Column(
                children: [
                  Expanded(
                    child: _MessageList(
                      messages: state.messages,
                      currentUserId:
                          context.read<AuthBloc>().state is Authenticated
                              ? (context.read<AuthBloc>().state
                                      as Authenticated)
                                  .user
                                  .uid
                              : '',
                    ),
                  ),
                  const _MessageInput(),
                ],
              ),
            );
          }
          return const Center(child: Text('No messages'));
        },
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  final String currentUserId;

  const _MessageList({required this.messages, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isCurrentUser = message.senderId == currentUserId;

        return Align(
          alignment:
              isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isCurrentUser ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isCurrentUser)
                  Text(
                    message.senderName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                Text(
                  message.content,
                  style: TextStyle(
                    color: isCurrentUser ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('hh:mm a').format(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        isCurrentUser
                            ? Colors.white.withOpacity(0.7)
                            : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MessageInput extends StatefulWidget {
  const _MessageInput();

  @override
  State<_MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<_MessageInput> {
  final _controller = TextEditingController();
  bool _isComposing = false;

  void _handleSubmitted(String text) {
    if (text.isEmpty) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    final message = ChatMessage(
      id: '',
      senderId: authState.user.uid,
      senderName: authState.user.displayName ?? 'Anonymous',
      content: text,
      timestamp: DateTime.now(),
      receiverId: '',
    );

    context.read<ChatBloc>().add(SendMessage(message));
    _controller.clear();
    setState(() {
      _isComposing = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: (text) {
                    setState(() {
                      _isComposing = text.isNotEmpty;
                    });
                  },
                  onSubmitted: _isComposing ? _handleSubmitted : null,
                  decoration: const InputDecoration(
                    hintText: 'Send a message',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed:
                    _isComposing
                        ? () => _handleSubmitted(_controller.text)
                        : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
