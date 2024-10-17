import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEventForm extends StatefulWidget {
  @override
  _AddEventFormState createState() => _AddEventFormState();
}

class _AddEventFormState extends State<AddEventForm> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEventType;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _organizerController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  DateTime? _getCombinedDateTime() {
    if (_selectedDate != null) {
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final String title = _titleController.text;
      final String description = _descriptionController.text;
      final String location = _locationController.text;
      final String organizer = _organizerController.text;
      final String eventType = _selectedEventType!;
      final DateTime? eventDateTime = _selectedDate;

      if (eventDateTime == null) {
        print('Please select date.');
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
          'createdAt':
              Timestamp.now(), // Optional: track when event was created
        });

        print('Event created successfully');
        Navigator.pop(
            context); // Close the form screen after successful submission
      } catch (error) {
        print('Error submitting form: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Event'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(labelText: 'Location'),
              ),
              TextFormField(
                controller: _organizerController,
                decoration: InputDecoration(labelText: 'Organizer'),
              ),
              ListTile(
                title: Text(_selectedDate == null
                    ? 'Select Event Date'
                    : 'Event Date: ${DateFormat.yMMMd().format(_selectedDate!)}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              // ListTile(
              //   title: Text(_selectedTime == null
              //       ? 'Select Event Time'
              //       : 'Event Time: ${_selectedTime!.format(context)}'),
              //   trailing: Icon(Icons.access_time),
              //   onTap: () => _selectTime(context),
              // ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Event Type'),
                value: _selectedEventType,
                items: ['Conference', 'Workshop', 'Webinar']
                    .map((type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedEventType = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select an event type' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
