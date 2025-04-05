// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../models/contact.dart';
// import '../models/event.dart';

// class NotificationService {
//   final FirebaseMessaging _messaging = FirebaseMessaging.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // Initialize notifications
//   Future<void> initialize() async {
//     // Request permission for notifications
//     await _messaging.requestPermission(alert: true, badge: true, sound: true);

//     // Get FCM token
//     final token = await _messaging.getToken();
//     if (token != null) {
//       await _updateUserFCMToken(token);
//     }

//     // Handle token refresh
//     _messaging.onTokenRefresh.listen(_updateUserFCMToken);

//     // Handle foreground messages
//     FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
//   }

//   // Update user's FCM token in Firestore
//   Future<void> _updateUserFCMToken(String token) async {
//     final user = FirebaseFirestore.instance.collection('users').doc();
//     await user.update({
//       'fcmToken': token,
//       'hasApp': true,
//       'lastSeen': FieldValue.serverTimestamp(),
//     });
//   }

//   // Handle incoming foreground messages
//   void _handleForegroundMessage(RemoteMessage message) {
//     // TODO: Show local notification or update UI
//   }

//   // Send chat message notification
//   Future<void> sendChatNotification({
//     required String recipientId,
//     required String senderName,
//     required String message,
//   }) async {
//     final recipient =
//         await _firestore.collection('users').doc(recipientId).get();
//     final fcmToken = recipient.data()?['fcmToken'];

//     if (fcmToken != null) {
//       await _sendFCMNotification(
//         token: fcmToken,
//         title: senderName,
//         body: message,
//         type: 'chat',
//       );
//     }
//   }

//   // Send event notification to attendees
//   Future<void> sendEventNotification(Event event) async {
//     for (final attendee in event.attendees) {
//       if (attendee['hasApp'] == true && attendee['fcmToken'] != null) {
//         // Send push notification to app users
//         await _sendFCMNotification(
//           token: attendee['fcmToken'],
//           title: 'New Event: ${event.title}',
//           body: 'You have been invited to ${event.title}',
//           type: 'event',
//           data: {
//             'eventId': event.id,
//             'startTime': event.startTime.toIso8601String(),
//           },
//         );
//       } else {
//         // Send email to non-app users
//         await _sendEventEmail(email: attendee['email'], event: event);
//       }
//     }
//   }

//   // Send FCM notification
//   Future<void> _sendFCMNotification({
//     required String token,
//     required String title,
//     required String body,
//     required String type,
//     Map<String, dynamic>? data,
//   }) async {
//     final response = await http.post(
//       Uri.parse('https://fcm.googleapis.com/fcm/send'),
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'key=YOUR_SERVER_KEY', // TODO: Add your FCM server key
//       },
//       body: jsonEncode({
//         'to': token,
//         'notification': {'title': title, 'body': body},
//         'data': {'type': type, ...?data},
//       }),
//     );

//     if (response.statusCode != 200) {
//       throw Exception('Failed to send notification');
//     }
//   }

//   // Send event email to non-app users
//   Future<void> _sendEventEmail({
//     required String email,
//     required Event event,
//   }) async {
//     // TODO: Implement email sending logic using your preferred email service
//     // This could be implemented using SendGrid, Amazon SES, or other email services
//   }
// }
