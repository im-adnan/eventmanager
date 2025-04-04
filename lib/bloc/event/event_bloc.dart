import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../models/event.dart';
import '../../services/google_calendar_service.dart';

// Events
abstract class EventEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadEvents extends EventEvent {}

class AddEvent extends EventEvent {
  final Event event;

  AddEvent(this.event);

  @override
  List<Object?> get props => [event];
}

class UpdateEvent extends EventEvent {
  final Event event;

  UpdateEvent(this.event);

  @override
  List<Object?> get props => [event];
}

class DeleteEvent extends EventEvent {
  final Event event;

  DeleteEvent(this.event);

  @override
  List<Object?> get props => [event];
}

// States
abstract class EventState extends Equatable {
  @override
  List<Object?> get props => [];
}

class EventInitial extends EventState {}

class EventLoading extends EventState {}

class EventsLoaded extends EventState {
  final List<Event> events;

  EventsLoaded(this.events);

  @override
  List<Object?> get props => [events];
}

class EventOperationSuccess extends EventState {}

class EventError extends EventState {
  final String message;

  EventError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class EventBloc extends Bloc<EventEvent, EventState> {
  final FirebaseFirestore _firestore;
  final GoogleCalendarService _calendarService;
  final String _userId;

  EventBloc(String userId)
    : _firestore = FirebaseFirestore.instance,
      _calendarService = GoogleCalendarService(),
      _userId = userId,
      super(EventInitial()) {
    on<LoadEvents>(_onLoadEvents);
    on<AddEvent>(_onAddEvent);
    on<UpdateEvent>(_onUpdateEvent);
    on<DeleteEvent>(_onDeleteEvent);
  }

  Future<void> _onLoadEvents(LoadEvents event, Emitter<EventState> emit) async {
    try {
      emit(EventLoading());
      final eventsSnapshot =
          await _firestore
              .collection('users')
              .doc(_userId)
              .collection('events')
              .orderBy('startTime')
              .get();

      final events =
          eventsSnapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();

      emit(EventsLoaded(events));
    } catch (e) {
      emit(EventError(e.toString()));
    }
  }

  Future<void> _onAddEvent(AddEvent event, Emitter<EventState> emit) async {
    try {
      emit(EventLoading());

      // Create event in Google Calendar
      final googleEventId = await _calendarService.createEvent(event.event);

      // Create event in Firestore with Google Calendar ID
      final eventWithGoogleId = event.event.copyWith(
        googleCalendarEventId: googleEventId,
      );

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('events')
          .add(eventWithGoogleId.toMap());

      add(LoadEvents());
    } catch (e) {
      emit(EventError(e.toString()));
    }
  }

  Future<void> _onUpdateEvent(
    UpdateEvent event,
    Emitter<EventState> emit,
  ) async {
    try {
      emit(EventLoading());

      // Update event in Google Calendar
      await _calendarService.updateEvent(event.event);

      // Update event in Firestore
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('events')
          .doc(event.event.id)
          .update(event.event.toMap());

      add(LoadEvents());
    } catch (e) {
      emit(EventError(e.toString()));
    }
  }

  Future<void> _onDeleteEvent(
    DeleteEvent event,
    Emitter<EventState> emit,
  ) async {
    try {
      emit(EventLoading());

      // Delete event from Google Calendar
      if (event.event.googleCalendarEventId != null) {
        await _calendarService.deleteEvent(event.event.googleCalendarEventId!);
      }

      // Delete event from Firestore
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('events')
          .doc(event.event.id)
          .delete();

      add(LoadEvents());
    } catch (e) {
      emit(EventError(e.toString()));
    }
  }
}
