import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/event/event_bloc.dart';
import '../../models/event.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => EventBloc(
            context.read<AuthBloc>().state is Authenticated
                ? (context.read<AuthBloc>().state as Authenticated).user.uid
                : '',
          )..add(LoadEvents()),
      child: BlocConsumer<EventBloc, EventState>(
        listener: (context, state) {
          if (state is EventError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is EventLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is EventsLoaded) {
            return _EventsList(events: state.events);
          }
          return const Center(child: Text('No events found'));
        },
      ),
    );
  }
}

class _EventsList extends StatelessWidget {
  final List<Event> events;

  const _EventsList({required this.events});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(
                event.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    DateFormat(
                      'MMM dd, yyyy • hh:mm a',
                    ).format(event.startTime),
                    style: const TextStyle(color: Colors.blue),
                  ),
                  const SizedBox(height: 2),
                  Text(event.description),
                  const SizedBox(height: 2),
                  if (event.location.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16),
                        const SizedBox(width: 4),
                        Text(event.location),
                      ],
                    ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  final eventBloc = context.read<EventBloc>();
                  showModalBottomSheet(
                    context: context,
                    builder:
                        (context) => BlocProvider.value(
                          value: eventBloc,
                          child: _EventActions(event: event),
                        ),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showEventDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEventDialog(BuildContext context, [Event? event]) {
    final eventBloc = context.read<EventBloc>();
    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: eventBloc,
            child: _EventDialog(event: event),
          ),
    );
  }
}

class _EventActions extends StatelessWidget {
  final Event event;

  const _EventActions({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Event'),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => _EventDialog(event: event),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text(
              'Delete Event',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              context.read<EventBloc>().add(DeleteEvent(event));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _EventDialog extends StatefulWidget {
  final Event? event;

  const _EventDialog({this.event});

  @override
  State<_EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<_EventDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late DateTime _startTime;
  late DateTime _endTime;
  final List<String> _attendees = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title);
    _descriptionController = TextEditingController(
      text: widget.event?.description,
    );
    _locationController = TextEditingController(text: widget.event?.location);
    _startTime = widget.event?.startTime ?? DateTime.now();
    _endTime =
        widget.event?.endTime ?? DateTime.now().add(const Duration(hours: 1));
    if (widget.event != null) {
      _attendees.addAll(widget.event!.attendees);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context, bool isStartTime) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: isStartTime ? _startTime : _endTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          isStartTime ? _startTime : _endTime,
        ),
      );

      if (time != null) {
        setState(() {
          if (isStartTime) {
            _startTime = DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            );
            // Ensure end time is after start time
            if (_endTime.isBefore(_startTime)) {
              _endTime = _startTime.add(const Duration(hours: 1));
            }
          } else {
            _endTime = DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            );
          }
        });
      }
    }
  }

  void _addAttendee(String email) {
    if (email.isNotEmpty && !_attendees.contains(email)) {
      setState(() {
        _attendees.add(email);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.event == null ? 'Add Event' : 'Edit Event'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Start Time'),
              subtitle: Text(
                DateFormat('MMM dd, yyyy • hh:mm a').format(_startTime),
              ),
              onTap: () => _selectDateTime(context, true),
            ),
            ListTile(
              title: const Text('End Time'),
              subtitle: Text(
                DateFormat('MMM dd, yyyy • hh:mm a').format(_endTime),
              ),
              onTap: () => _selectDateTime(context, false),
            ),
            const SizedBox(height: 16),
            // Attendees section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Attendees'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ..._attendees.map(
                      (email) => Chip(
                        label: Text(email),
                        onDeleted: () {
                          setState(() {
                            _attendees.remove(email);
                          });
                        },
                      ),
                    ),
                    ActionChip(
                      label: const Icon(Icons.add, size: 20),
                      onPressed: () async {
                        final email = await showDialog<String>(
                          context: context,
                          builder: (context) => _AddAttendeeDialog(),
                        );
                        if (email != null) {
                          _addAttendee(email);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final event = Event(
              id: widget.event?.id ?? '',
              title: _titleController.text,
              description: _descriptionController.text,
              startTime: _startTime,
              endTime: _endTime,
              location: _locationController.text,
              attendees: _attendees,
              googleCalendarEventId: widget.event?.googleCalendarEventId,
              createdAt: widget.event?.createdAt ?? DateTime.now(),
              updatedAt: DateTime.now(),
            );

            if (widget.event == null) {
              context.read<EventBloc>().add(AddEvent(event));
            } else {
              context.read<EventBloc>().add(UpdateEvent(event));
            }

            Navigator.pop(context);
          },
          child: Text(widget.event == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}

class _AddAttendeeDialog extends StatefulWidget {
  @override
  State<_AddAttendeeDialog> createState() => _AddAttendeeDialogState();
}

class _AddAttendeeDialogState extends State<_AddAttendeeDialog> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Attendee'),
      content: TextField(
        controller: _emailController,
        decoration: const InputDecoration(labelText: 'Email'),
        keyboardType: TextInputType.emailAddress,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _emailController.text),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
