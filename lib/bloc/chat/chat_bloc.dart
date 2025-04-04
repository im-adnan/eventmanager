import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../models/chat_message.dart';

// Events
abstract class ChatEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadMessages extends ChatEvent {}

class SendMessage extends ChatEvent {
  final ChatMessage message;

  SendMessage(this.message);

  @override
  List<Object?> get props => [message];
}

class MessageReceived extends ChatEvent {
  final ChatMessage message;

  MessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}

class MarkMessageAsRead extends ChatEvent {
  final String messageId;

  MarkMessageAsRead(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

// States
abstract class ChatState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;

  ChatLoaded(this.messages);

  @override
  List<Object?> get props => [messages];
}

class ChatError extends ChatState {
  final String message;

  ChatError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;
  final String _userId;
  StreamSubscription<QuerySnapshot>? _messagesSubscription;

  ChatBloc(String userId)
    : _firestore = FirebaseFirestore.instance,
      _messaging = FirebaseMessaging.instance,
      _userId = userId,
      super(ChatInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
    on<MessageReceived>(_onMessageReceived);
    on<MarkMessageAsRead>(_onMarkMessageAsRead);

    _initializeMessaging();
    _subscribeToMessages();
  }

  Future<void> _initializeMessaging() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final data = message.data;
      if (data['type'] == 'chat_message') {
        add(
          MessageReceived(
            ChatMessage(
              id: data['messageId'],
              senderId: data['senderId'],
              senderName: data['senderName'],
              content: data['content'],
              timestamp: DateTime.fromMillisecondsSinceEpoch(
                int.parse(data['timestamp']),
              ),
              isRead: false,
            ),
          ),
        );
      }
    });
  }

  void _subscribeToMessages() {
    _messagesSubscription = _firestore
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            final messages =
                snapshot.docs
                    .map((doc) => ChatMessage.fromFirestore(doc))
                    .toList();
            emit(ChatLoaded(messages));
          },
          onError: (error) {
            emit(ChatError(error.toString()));
          },
        );
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(ChatLoading());
      final messagesSnapshot =
          await _firestore
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .get();

      final messages =
          messagesSnapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList();

      emit(ChatLoaded(messages));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _firestore.collection('messages').add(event.message.toMap());

      // No need to emit new state as the stream will handle it
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  void _onMessageReceived(MessageReceived event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentMessages = (state as ChatLoaded).messages;
      emit(ChatLoaded([event.message, ...currentMessages]));
    }
  }

  Future<void> _onMarkMessageAsRead(
    MarkMessageAsRead event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _firestore.collection('messages').doc(event.messageId).update({
        'isRead': true,
      });

      // No need to emit new state as the stream will handle it
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
