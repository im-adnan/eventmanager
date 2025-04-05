import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Contact extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool hasApp;
  final bool isOnline;
  final String? fcmToken;

  const Contact({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.hasApp = false,
    this.isOnline = false,
    this.fcmToken,
  });

  factory Contact.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Contact(
      id: doc.id,
      name: data['name'] as String,
      email: data['email'] as String,
      phone: data['phone'] as String?,
      photoUrl: data['photoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      hasApp: data['hasApp'] as bool? ?? false,
      isOnline: data['isOnline'] as bool? ?? false,
      fcmToken: data['fcmToken'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'hasApp': hasApp,
      'isOnline': isOnline,
      'fcmToken': fcmToken,
    };
  }

  Contact copyWith({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
  }) {
    return Contact(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phone,
    photoUrl,
    createdAt,
    updatedAt,
  ];
}
