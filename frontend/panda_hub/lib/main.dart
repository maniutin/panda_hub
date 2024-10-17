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
        final List<dynamic> decodedEvents = json.decode(response.body);

        // Debugging: Log each event to check its structure
        for (var event in decodedEvents) {
          print(event); // Check if updatedAt exists and its format
        }

        setState(() {
          events = decodedEvents;
          isLoading = false;
        });
      } else {
        // Handle the error, perhaps show a message to the user
        throw Exception('Failed to load events');
      }
    } catch (error) {
      // Handle the error, e.g. show a Snackbar or message
      setState(() {
        isLoading = false;
      });
      print('Error fetching events: $error');
    }
  }

  // Function to handle Firestore Timestamp format
  DateTime? convertFirestoreTimestamp(dynamic timestamp) {
    if (timestamp is Map && timestamp.containsKey('seconds')) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp['seconds'] * 1000);
    }
    return null; // Return null if the timestamp is missing/invalid
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event List'),
      ),
      body: isLoading
          ? Center(
              child:
                  CircularProgressIndicator()) // Show loading indicator while fetching data
          : events.isEmpty
              ? Center(
                  child: Text(
                      'No events found')) // Show message if no events found
              : ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];

                    // Convert Firestore Timestamps to DateTime using the helper function
                    DateTime? eventDate =
                        convertFirestoreTimestamp(event['date']);
                    DateTime? updatedAt =
                        convertFirestoreTimestamp(event['updatedAt']);

                    // If updatedAt is null, show "Unknown" or any other placeholder
                    String updatedAtText = updatedAt != null
                        ? updatedAt.toLocal().toString()
                        : 'Unknown';

                    return Card(
                      margin: EdgeInsets.all(10),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event['title'],
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
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
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
