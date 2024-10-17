import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'add_event_form.dart';

class EventListScreen extends StatefulWidget {
  @override
  _EventListScreenState createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  List<Map<String, dynamic>> events = [];
  List<Map<String, dynamic>> filteredEvents = [];
  bool isLoading = false;
  String? selectedFilter = 'All'; // Store the selected event type filter
  Map<int, bool> expandedStates = {}; // Track expanded state for each event
  Map<int, bool> isEditing = {}; // Track editing state for each event
  late Stream<QuerySnapshot> _eventsStream; // Stream to listen for changes

  @override
  void initState() {
    super.initState();
    _eventsStream = FirebaseFirestore.instance
        .collection('events')
        .orderBy('date', descending: false)
        .snapshots(); // Stream that listens for changes
  }

  void showSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void filterEvents(String? eventType) {
    setState(() {
      selectedFilter = eventType;
      if (eventType == null || eventType == 'All') {
        filteredEvents =
            events; // Show all events if no filter or "All" is selected
      } else {
        filteredEvents = events
            .where((event) => event['eventType'] == eventType)
            .toList(); // Filter events based on type
      }
    });
  }

  Future<void> updateEvent(dynamic event) async {
    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(event['id'])
          .update({
        'title': event['title'],
        'description': event['description'],
        'location': event['location'],
        'organizer': event['organizer'],
        'eventType': event['eventType'],
        'date': event['date'],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      showSnackBar(context, 'Event updated successfully');
    } catch (error) {
      print('Error updating event: $error');
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .delete();

      showSnackBar(context, 'Event deleted successfully');
    } catch (error) {
      print('Error deleting event: $error');
    }
  }

  Future<void> _selectDate(BuildContext context, int index) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        events[index]['date'] = Timestamp.fromDate(picked);
      });

      // Update the event in Firestore
      updateEvent(
          events[index]); // prevent fetching event date again from stream
    }
  }

  // Future<void> _selectTime(BuildContext context, int index) async {
  //   final TimeOfDay? picked = await showTimePicker(
  //     context: context,
  //     initialTime: TimeOfDay.now(),
  //   );
  //   if (picked != null) {
  //     final DateTime currentDate =
  //         (events[index]['date'] as Timestamp).toDate();
  //     final updatedDate = DateTime(
  //       currentDate.year,
  //       currentDate.month,
  //       currentDate.day,
  //       picked.hour,
  //       picked.minute,
  //     );
  //     setState(() {
  //       events[index]['date'] = Timestamp.fromDate(updatedDate);
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event List'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _eventsStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading events'));
          }

          final List<Map<String, dynamic>> fetchedEvents =
              snapshot.data!.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              ...data,
            };
          }).toList();

          events = fetchedEvents;
          filteredEvents = (selectedFilter == null || selectedFilter == 'All')
              ? events
              : events
                  .where((event) => event['eventType'] == selectedFilter)
                  .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Filter by Event Type',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedFilter,
                  items: [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(
                        value: 'Conference', child: Text('Conference')),
                    DropdownMenuItem(
                        value: 'Workshop', child: Text('Workshop')),
                    DropdownMenuItem(value: 'Webinar', child: Text('Webinar')),
                  ],
                  onChanged: (value) {
                    filterEvents(value);
                  },
                ),
              ),
              Expanded(
                child: filteredEvents.isEmpty
                    ? Center(child: Text('No events found'))
                    : ListView.builder(
                        itemCount: filteredEvents.length,
                        itemBuilder: (context, index) {
                          final event = filteredEvents[index];

                          DateTime eventDate = (event['date']).toDate();

                          String updatedAtText =
                              event.containsKey('updatedAt') &&
                                      event['updatedAt'] != null
                                  ? (event['updatedAt'] as Timestamp)
                                      .toDate()
                                      .toLocal()
                                      .toString()
                                  : 'Not updated';

                          bool isExpanded = expandedStates[index] ?? false;
                          bool editMode = isEditing[index] ?? false;

                          if (editMode) {
                            // Edit Mode
                            return Card(
                              margin: EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    title: TextFormField(
                                      initialValue: event['title'],
                                      decoration:
                                          InputDecoration(labelText: 'Title'),
                                      onChanged: (value) {
                                        event['title'] = value;
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        TextFormField(
                                          initialValue: event['description'],
                                          decoration: InputDecoration(
                                              labelText: 'Description'),
                                          onChanged: (value) {
                                            event['description'] = value;
                                          },
                                        ),
                                        SizedBox(height: 5),
                                        TextFormField(
                                          initialValue: event['location'],
                                          decoration: InputDecoration(
                                              labelText: 'Location'),
                                          onChanged: (value) {
                                            event['location'] = value;
                                          },
                                        ),
                                        SizedBox(height: 5),
                                        TextFormField(
                                          initialValue: event['organizer'],
                                          decoration: InputDecoration(
                                              labelText: 'Organizer'),
                                          onChanged: (value) {
                                            event['organizer'] = value;
                                          },
                                        ),
                                        SizedBox(height: 5),
                                        DropdownButtonFormField<String>(
                                          value: event['eventType'],
                                          items: [
                                            DropdownMenuItem(
                                                value: 'Conference',
                                                child: Text('Conference')),
                                            DropdownMenuItem(
                                                value: 'Workshop',
                                                child: Text('Workshop')),
                                            DropdownMenuItem(
                                                value: 'Webinar',
                                                child: Text('Webinar')),
                                          ],
                                          onChanged: (value) {
                                            event['eventType'] = value!;
                                          },
                                          decoration: InputDecoration(
                                              labelText: 'Event Type'),
                                        ),
                                        SizedBox(height: 5),
                                        ListTile(
                                          title: Text(
                                              'Event Date: ${DateFormat.yMMMd().format(eventDate)}'),
                                          trailing: Icon(Icons.calendar_today),
                                          onTap: () =>
                                              _selectDate(context, index),
                                        ),
                                        SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () {
                                                updateEvent(event);
                                                setState(() {
                                                  isEditing[index] = false;
                                                });
                                              },
                                              child: Text('Submit'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  isEditing[index] = false;
                                                });
                                              },
                                              child: Text('Cancel'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            // Display Event
                            return ExpansionTile(
                              title: Text(event['title']),
                              initiallyExpanded: isExpanded,
                              onExpansionChanged: (value) {
                                setState(() {
                                  expandedStates[index] = value;
                                });
                              },
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          'Description: ${event['description']}'),
                                      Text('Location: ${event['location']}'),
                                      Text('Organizer: ${event['organizer']}'),
                                      Text('Event Type: ${event['eventType']}'),
                                      Text(
                                          'Event Date: ${DateFormat.yMMMd().format(eventDate)}'),
                                      Text('Last Updated: $updatedAtText'),
                                      SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                isEditing[index] = true;
                                              });
                                            },
                                            child: Text('Edit'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              deleteEvent(event['id']);
                                            },
                                            child: Text('Delete'),
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          bool? shouldRefresh = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddEventForm()),
          );
          if (shouldRefresh == true) {
            // Manual refresh can still be triggered after adding new events.
            setState(() {});
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
