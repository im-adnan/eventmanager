import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart';
import '../models/event.dart';

class GoogleCalendarService {
  final GoogleSignIn _googleSignIn;
  calendar.CalendarApi? _calendarApi;

  GoogleCalendarService()
    : _googleSignIn = GoogleSignIn(
        scopes: ['email', 'https://www.googleapis.com/auth/calendar'],
      );

  Future<void> init() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google Sign In failed');

    final authHeaders = await googleUser.authHeaders;

    final client = GoogleAuthClient(authHeaders);
    _calendarApi = calendar.CalendarApi(client as Client);
  }

  Future<String> createEvent(
    Event event, {
    required String title,
    required String description,
    required String location,
    required DateTime startTime,
    required DateTime endTime,
    required List<String> attendees,
    required String organizerEmail,
  }) async {
    if (_calendarApi == null) await init();

    final calendarEvent =
        calendar.Event()
          ..summary = event.title
          ..description = event.description
          ..start =
              (calendar.EventDateTime()
                ..dateTime = event.startTime.toUtc()
                ..timeZone = 'UTC')
          ..end =
              (calendar.EventDateTime()
                ..dateTime = event.endTime.toUtc()
                ..timeZone = 'UTC')
          ..location = event.location
          ..attendees =
              event.attendees
                  .map((email) => calendar.EventAttendee()..email = email)
                  .toList();

    final response = await _calendarApi!.events.insert(
      calendarEvent,
      'primary',
    );
    return response.id!;
  }

  Future<void> updateEvent(Event event) async {
    if (_calendarApi == null) await init();
    if (event.googleCalendarEventId == null) {
      throw Exception('No Google Calendar Event ID found');
    }

    final calendarEvent =
        calendar.Event()
          ..summary = event.title
          ..description = event.description
          ..start =
              (calendar.EventDateTime()
                ..dateTime = event.startTime.toUtc()
                ..timeZone = 'UTC')
          ..end =
              (calendar.EventDateTime()
                ..dateTime = event.endTime.toUtc()
                ..timeZone = 'UTC')
          ..location = event.location
          ..attendees =
              event.attendees
                  .map((email) => calendar.EventAttendee()..email = email)
                  .toList();

    await _calendarApi!.events.update(
      calendarEvent,
      'primary',
      event.googleCalendarEventId!,
    );
  }

  Future<void> deleteEvent(String eventId) async {
    if (_calendarApi == null) await init();
    await _calendarApi!.events.delete('primary', eventId);
  }

  Future<List<calendar.Event>> getEvents({
    DateTime? timeMin,
    DateTime? timeMax,
  }) async {
    if (_calendarApi == null) await init();

    final events = await _calendarApi!.events.list(
      'primary',
      timeMin: timeMin?.toUtc(),
      timeMax: timeMax?.toUtc(),
      singleEvents: true,
      orderBy: 'startTime',
    );

    return events.items ?? [];
  }
}

class GoogleAuthClient extends BaseClient {
  final Map<String, String> _headers;
  final Client _client = Client();

  GoogleAuthClient(this._headers);

  @override
  Future<StreamedResponse> send(BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}
