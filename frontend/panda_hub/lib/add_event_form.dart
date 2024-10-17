import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

// Model for event data
class EventModel extends ChangeNotifier {
  String? _selectedEventType;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController organizerController = TextEditingController();

  String? get selectedEventType => _selectedEventType;
  DateTime? get selectedDate => _selectedDate;
  TimeOfDay? get selectedTime => _selectedTime;

  set selectedEventType(String? eventType) {
    _selectedEventType = eventType;
    notifyListeners();
  }

  set selectedDate(DateTime? date) {
    _selectedDate = date;
    notifyListeners();
  }

  set selectedTime(TimeOfDay? time) {
    _selectedTime = time;
    notifyListeners();
  }

  DateTime? getCombinedDateTime() {
    if (_selectedDate != null && _selectedTime != null) {
      return DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
    }
    return null;
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      selectedDate = picked;
    }
  }

  Future<void> selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      selectedTime = picked;
    }
  }

  Future<void> submitForm(
      BuildContext context, GlobalKey<FormState> formKey) async {
    if (formKey.currentState!.validate()) {
      final String title = titleController.text;
      final String description = descriptionController.text;
      final String location = locationController.text;
      final String organizer = organizerController.text;
      final String eventType = _selectedEventType!;
      final DateTime? eventDateTime = _selectedDate;

      if (eventDateTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Please select a date.'),
        ));
        return;
      }

      try {
        // Add event to Firestore
        await FirebaseFirestore.instance.collection('events').add({
          'title': title,
          'description': description,
          'location': location,
          'organizer': organizer,
          'eventType': eventType,
          'date': eventDateTime,
          'createdAt': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Event created successfully'),
        ));
        Navigator.pop(context);
      } catch (error) {
        print('Error submitting form: $error');
      }
    }
  }
}

class AddEventForm extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EventModel(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Add Event'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Consumer<EventModel>(
            builder: (context, model, child) => Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: model.titleController,
                    decoration: InputDecoration(labelText: 'Title'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: model.descriptionController,
                    decoration: InputDecoration(labelText: 'Description'),
                  ),
                  TextFormField(
                    controller: model.locationController,
                    decoration: InputDecoration(labelText: 'Location'),
                  ),
                  TextFormField(
                    controller: model.organizerController,
                    decoration: InputDecoration(labelText: 'Organizer'),
                  ),
                  ListTile(
                    title: Text(model.selectedDate == null
                        ? 'Select Event Date'
                        : 'Event Date: ${DateFormat.yMMMd().format(model.selectedDate!)}'),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () => model.selectDate(context),
                  ),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: 'Event Type'),
                    value: model.selectedEventType,
                    items: ['Conference', 'Workshop', 'Webinar']
                        .map((type) => DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (newValue) {
                      model.selectedEventType = newValue;
                    },
                    validator: (value) =>
                        value == null ? 'Please select an event type' : null,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => model.submitForm(context, _formKey),
                    child: Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
