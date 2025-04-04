import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../models/contact.dart';

// Events
abstract class ContactEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadContacts extends ContactEvent {}

class AddContact extends ContactEvent {
  final Contact contact;

  AddContact(this.contact);

  @override
  List<Object?> get props => [contact];
}

class UpdateContact extends ContactEvent {
  final Contact contact;

  UpdateContact(this.contact);

  @override
  List<Object?> get props => [contact];
}

class DeleteContact extends ContactEvent {
  final String contactId;

  DeleteContact(this.contactId);

  @override
  List<Object?> get props => [contactId];
}

// States
abstract class ContactState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ContactInitial extends ContactState {}

class ContactLoading extends ContactState {}

class ContactsLoaded extends ContactState {
  final List<Contact> contacts;

  ContactsLoaded(this.contacts);

  @override
  List<Object?> get props => [contacts];
}

class ContactOperationSuccess extends ContactState {}

class ContactError extends ContactState {
  final String message;

  ContactError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class ContactBloc extends Bloc<ContactEvent, ContactState> {
  final FirebaseFirestore _firestore;
  final String _userId;

  ContactBloc(String userId)
    : _firestore = FirebaseFirestore.instance,
      _userId = userId,
      super(ContactInitial()) {
    on<LoadContacts>(_onLoadContacts);
    on<AddContact>(_onAddContact);
    on<UpdateContact>(_onUpdateContact);
    on<DeleteContact>(_onDeleteContact);
  }

  Future<void> _onLoadContacts(
    LoadContacts event,
    Emitter<ContactState> emit,
  ) async {
    try {
      emit(ContactLoading());
      final contactsSnapshot =
          await _firestore
              .collection('users')
              .doc(_userId)
              .collection('contacts')
              .orderBy('name')
              .get();

      final contacts =
          contactsSnapshot.docs
              .map((doc) => Contact.fromFirestore(doc))
              .toList();

      emit(ContactsLoaded(contacts));
    } catch (e) {
      emit(ContactError(e.toString()));
    }
  }

  Future<void> _onAddContact(
    AddContact event,
    Emitter<ContactState> emit,
  ) async {
    try {
      emit(ContactLoading());
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('contacts')
          .add(event.contact.toMap());

      add(LoadContacts());
    } catch (e) {
      emit(ContactError(e.toString()));
    }
  }

  Future<void> _onUpdateContact(
    UpdateContact event,
    Emitter<ContactState> emit,
  ) async {
    try {
      emit(ContactLoading());
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('contacts')
          .doc(event.contact.id)
          .update(event.contact.toMap());

      add(LoadContacts());
    } catch (e) {
      emit(ContactError(e.toString()));
    }
  }

  Future<void> _onDeleteContact(
    DeleteContact event,
    Emitter<ContactState> emit,
  ) async {
    try {
      emit(ContactLoading());
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('contacts')
          .doc(event.contactId)
          .delete();

      add(LoadContacts());
    } catch (e) {
      emit(ContactError(e.toString()));
    }
  }
}
