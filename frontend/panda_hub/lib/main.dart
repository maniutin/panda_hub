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
        setState(() {
          events = json.decode(response.body);
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
                    return ListTile(
                      title: Text(event['title']),
                      subtitle: Text('Organizer: ${event['organizer']}'),
                      trailing: Text(event['eventType']),
                    );
                  },
                ),
    );
  }
}
