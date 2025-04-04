import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/contact/contact_bloc.dart';
import '../../models/contact.dart';
import '../../bloc/auth/auth_bloc.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return const Center(child: Text('Please sign in to view contacts'));
        }

        return BlocProvider(
          create:
              (context) => ContactBloc(authState.user.uid)..add(LoadContacts()),
          child: BlocConsumer<ContactBloc, ContactState>(
            listener: (context, state) {
              if (state is ContactError) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              }
            },
            builder: (context, state) {
              if (state is ContactLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is ContactsLoaded) {
                return _ContactsList(contacts: state.contacts);
              }
              if (state is ContactError) {
                return Center(child: Text(state.message));
              }
              return const Center(child: Text('No contacts found'));
            },
          ),
        );
      },
    );
  }
}

class _ContactsList extends StatelessWidget {
  final List<Contact> contacts;

  const _ContactsList({required this.contacts});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          final contact = contacts[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  contact.photoUrl != null
                      ? NetworkImage(contact.photoUrl!)
                      : null,
              child:
                  contact.photoUrl == null
                      ? Text(contact.name[0].toUpperCase())
                      : null,
            ),
            title: Text(contact.name),
            subtitle: Text(contact.email),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => _ContactActions(contact: contact),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showContactDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showContactDialog(BuildContext context, [Contact? contact]) {
    showDialog(
      context: context,
      builder: (context) => _ContactDialog(contact: contact),
    );
  }
}

class _ContactActions extends StatelessWidget {
  final Contact contact;

  const _ContactActions({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Contact'),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => _ContactDialog(contact: contact),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text(
              'Delete Contact',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              context.read<ContactBloc>().add(DeleteContact(contact.id));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _ContactDialog extends StatefulWidget {
  final Contact? contact;

  const _ContactDialog({this.contact});

  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact?.name);
    _emailController = TextEditingController(text: widget.contact?.email);
    _phoneController = TextEditingController(text: widget.contact?.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.contact == null ? 'Add Contact' : 'Edit Contact'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone'),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final contact = Contact(
              id: widget.contact?.id ?? '',
              name: _nameController.text,
              email: _emailController.text,
              phone: _phoneController.text,
              photoUrl: widget.contact?.photoUrl,
              createdAt: widget.contact?.createdAt ?? DateTime.now(),
              updatedAt: DateTime.now(),
            );

            if (widget.contact == null) {
              context.read<ContactBloc>().add(AddContact(contact));
            } else {
              context.read<ContactBloc>().add(UpdateContact(contact));
            }

            Navigator.pop(context);
          },
          child: Text(widget.contact == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
