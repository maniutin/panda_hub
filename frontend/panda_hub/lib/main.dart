import 'package:flutter/material.dart';
import 'dart:convert'; // For JSON decoding
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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
  Map<int, bool> expandedStates = {}; // Track expanded state for each event
  Map<int, bool> editStates = {}; // Track editing state for each event
  Map<int, TextEditingController> titleControllers = {};
  Map<int, TextEditingController> descriptionControllers = {};
  Map<int, TextEditingController> locationControllers = {};
  Map<int, TextEditingController> organizerControllers = {};
  Map<int, String?> eventTypeSelections = {};

  final List<String> eventTypes = ['Conference', 'Workshop', 'Webinar'];

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
        final List<dynamic> decodedEvents = json.decode(response.body);
        setState(() {
          events = decodedEvents;
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

  DateTime? convertFirestoreTimestamp(dynamic timestamp) {
    if (timestamp.containsKey('_seconds')) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp['_seconds'] * 1000);
    }
    return null;
  }

  Future<void> updateEvent(dynamic event) async {
    final url = Uri.parse(
        'http://127.0.0.1:5001/panda-hub-a4da9/us-central1/updateEvent');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id': event['id'], // Event ID
          'title': event['title'],
          'description': event['description'],
          'location': event['location'],
          'organizer': event['organizer'],
          'eventType': event['eventType'],
          'date': event['date'],
        }),
      );

      if (response.statusCode == 200) {
        print('Event updated successfully');
        fetchEvents(); // Refresh the event list after updating
      } else {
        print('Failed to update event: ${response.statusCode}');
      }
    } catch (error) {
      print('Error updating event: $error');
    }
  }

  Future<void> deleteEvent(String eventId) async {
    final url = Uri.parse(
        'http://127.0.0.1:5001/panda-hub-a4da9/us-central1/deleteEvent');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id': eventId, // Event ID
        }),
      );

      if (response.statusCode == 200) {
        print('Event deleted successfully');
        fetchEvents(); // Refresh the event list after deleting
      } else {
        print('Failed to delete event: ${response.statusCode}');
      }
    } catch (error) {
      print('Error deleting event: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event List'),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : events.isEmpty
              ? Center(child: Text('No events found'))
              : ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];

                    DateTime? eventDate =
                        convertFirestoreTimestamp(event['date']);
                    DateTime? updatedAt =
                        convertFirestoreTimestamp(event['updatedAt']);

                    String updatedAtText = updatedAt != null
                        ? updatedAt.toLocal().toString()
                        : 'Unknown';

                    bool isExpanded = expandedStates[index] ?? false;
                    bool isEditing = editStates[index] ?? false;

                    if (!titleControllers.containsKey(index)) {
                      titleControllers[index] =
                          TextEditingController(text: event['title']);
                      descriptionControllers[index] =
                          TextEditingController(text: event['description']);
                      locationControllers[index] =
                          TextEditingController(text: event['location']);
                      organizerControllers[index] =
                          TextEditingController(text: event['organizer']);
                      eventTypeSelections[index] = event['eventType'];
                    }

                    return Card(
                      margin: EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: isEditing
                                ? TextFormField(
                                    controller: titleControllers[index],
                                    decoration:
                                        InputDecoration(labelText: 'Title'),
                                  )
                                : Text(
                                    event['title'],
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                            trailing: IconButton(
                              icon: Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                              ),
                              onPressed: () {
                                setState(() {
                                  expandedStates[index] = !isExpanded;
                                });
                              },
                            ),
                          ),
                          if (isExpanded)
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isEditing)
                                    Column(
                                      children: [
                                        TextFormField(
                                          controller:
                                              descriptionControllers[index],
                                          decoration: InputDecoration(
                                              labelText: 'Description'),
                                        ),
                                        TextFormField(
                                          controller:
                                              locationControllers[index],
                                          decoration: InputDecoration(
                                              labelText: 'Location'),
                                        ),
                                        TextFormField(
                                          controller:
                                              organizerControllers[index],
                                          decoration: InputDecoration(
                                              labelText: 'Organizer'),
                                        ),
                                        DropdownButtonFormField<String>(
                                          decoration: InputDecoration(
                                              labelText: 'Event Type'),
                                          value: eventTypeSelections[index],
                                          items: eventTypes
                                              .map((type) =>
                                                  DropdownMenuItem<String>(
                                                    value: type,
                                                    child: Text(type),
                                                  ))
                                              .toList(),
                                          onChanged: (newValue) {
                                            setState(() {
                                              eventTypeSelections[index] =
                                                  newValue;
                                              event['eventType'] = newValue;
                                            });
                                          },
                                        ),
                                      ],
                                    )
                                  else ...[
                                    Text(
                                      'Description: ${event['description']}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Location: ${event['location']}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Organizer: ${event['organizer']}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                  SizedBox(height: 5),
                                  Text(
                                    'Event Type: ${event['eventType']}',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Date: ${eventDate != null ? eventDate.toLocal().toString() : 'Unknown'}',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Last Updated: $updatedAtText',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      if (isEditing)
                                        ElevatedButton(
                                          onPressed: () {
                                            // Save the updates
                                            setState(() {
                                              event['title'] =
                                                  titleControllers[index]!.text;
                                              event['description'] =
                                                  descriptionControllers[index]!
                                                      .text;
                                              event['location'] =
                                                  locationControllers[index]!
                                                      .text;
                                              event['organizer'] =
                                                  organizerControllers[index]!
                                                      .text;
                                              editStates[index] = false;
                                            });
                                            updateEvent(event);
                                          },
                                          child: Text('Submit'),
                                        )
                                      else
                                        ElevatedButton(
                                          onPressed: () {
                                            // Enter edit mode
                                            setState(() {
                                              editStates[index] = true;
                                            });
                                          },
                                          child: Text('Edit'),
                                        ),
                                      ElevatedButton(
                                        onPressed: () {
                                          deleteEvent(event['id']);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
