import 'package:flutter/material.dart';
import 'dart:convert'; // For JSON decoding
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: EventListScreen(),
    );
  }
}

class EventListScreen extends StatefulWidget {
  @override
  _EventListScreenState createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  List<dynamic> events = [];
  bool isLoading = false;
  bool showForm = false; // To toggle form visibility

  // Form field controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  String _eventType = 'Conference'; // Default event type
  final _locationController = TextEditingController();
  final _organizerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse(
        'http://127.0.0.1:5001/panda-hub-a4da9/us-central1/getAllEvents');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Decode the JSON response and update the state with the list of events
        setState(() {
          events = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load events');
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching events: $error');
    }
  }

  // Function to send event data to the server
  Future<void> submitEvent() async {
    final url = Uri.parse(
        'http://127.0.0.1:5001/panda-hub-a4da9/us-central1/createEvent');

    // Prepare the data to send
    final eventData = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'date': _selectedDate?.toIso8601String(),
      'eventType': _eventType,
      'location': _locationController.text,
      'organizer': _organizerController.text,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(eventData),
      );

      if (response.statusCode == 200) {
        print('Event created successfully');
        fetchEvents(); // Refresh event list after creation
        setState(() {
          showForm = false; // Hide the form after submission
          _clearForm(); // Clear the form fields
        });
      } else {
        print('Failed to create event: ${response.body}');
      }
    } catch (error) {
      print('Error submitting event: $error');
    }
  }

  // Clear form fields
  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _selectedDate = null;
    _eventType = 'Conference';
    _locationController.clear();
    _organizerController.clear();
  }

  // Function to show date picker
  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event List'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              setState(() {
                showForm = !showForm; // Toggle form visibility
              });
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (showForm)
                  buildEventForm(), // Display the form if showForm is true
                Expanded(
                  child: events.isEmpty
                      ? Center(child: Text('No events found'))
                      : ListView.builder(
                          itemCount: events.length,
                          itemBuilder: (context, index) {
                            final event = events[index];
                            return Card(
                              margin: EdgeInsets.all(10),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event['title'] ?? 'No Title',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Description: ${event['description'] ?? 'No Description'}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Location: ${event['location'] ?? 'No Location'}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Organizer: ${event['organizer'] ?? 'No Organizer'}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Event Type: ${event['eventType'] ?? 'No Type'}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Date: ${event['date'] ?? 'No Date'}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  // Widget for the event creation form
  Widget buildEventForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(labelText: 'Title'),
          ),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(labelText: 'Description'),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Text(
                _selectedDate == null
                    ? 'Select Date'
                    : 'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
              ),
              SizedBox(width: 20),
              ElevatedButton(
                onPressed: () => _pickDate(context),
                child: Text('Pick Date'),
              ),
            ],
          ),
          DropdownButton<String>(
            value: _eventType,
            onChanged: (String? newValue) {
              setState(() {
                _eventType = newValue!;
              });
            },
            items: <String>['Conference', 'Workshop', 'Webinar']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          TextField(
            controller: _locationController,
            decoration: InputDecoration(labelText: 'Location'),
          ),
          TextField(
            controller: _organizerController,
            decoration: InputDecoration(labelText: 'Organizer'),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: submitEvent,
            child: Text('Submit Event'),
          ),
        ],
      ),
    );
  }
}
