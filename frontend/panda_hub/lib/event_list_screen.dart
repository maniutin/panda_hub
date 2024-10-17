import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'add_event_form.dart';
import 'snackbar.dart';

class EventProvider extends ChangeNotifier {
  List<Map<String, dynamic>> events = [];
  List<Map<String, dynamic>> filteredEvents = [];
  String? selectedFilter = 'All';
  Map<int, bool> expandedStates = {};
  Map<int, bool> isEditing = {};
  late Stream<QuerySnapshot> _eventsStream;

  EventProvider() {
    _eventsStream = FirebaseFirestore.instance
        .collection('events')
        .orderBy('date', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot> get eventsStream => _eventsStream;

  void filterEvents(String? eventType) {
    selectedFilter = eventType;
    if (eventType == null || eventType == 'All') {
      filteredEvents = events;
    } else {
      filteredEvents =
          events.where((event) => event['eventType'] == eventType).toList();
    }
    notifyListeners();
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
    } catch (error) {
      print('Error updating event: $error');
    }
    notifyListeners();
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .delete();
    } catch (error) {
      print('Error deleting event: $error');
    }
    notifyListeners();
  }

  Future<void> selectDate(BuildContext context, int index) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      events[index]['date'] = Timestamp.fromDate(picked);
      updateEvent(events[index]);
    }
    notifyListeners();
  }

  void setEvents(List<Map<String, dynamic>> fetchedEvents) {
    events = fetchedEvents;
    filterEvents(selectedFilter);
    notifyListeners();
  }

  void toggleEditing(int index, bool editMode) {
    isEditing[index] = editMode;
    notifyListeners();
  }

  void toggleExpandedState(int index, bool isExpanded) {
    expandedStates[index] = isExpanded;
    notifyListeners();
  }
}

class EventListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EventProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Event List'),
        ),
        body: Consumer<EventProvider>(
          builder: (context, eventProvider, _) {
            return StreamBuilder<QuerySnapshot>(
              stream: eventProvider.eventsStream,
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
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

                eventProvider.setEvents(fetchedEvents);

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Filter by Event Type',
                          border: OutlineInputBorder(),
                        ),
                        value: eventProvider.selectedFilter,
                        items: [
                          DropdownMenuItem(value: 'All', child: Text('All')),
                          DropdownMenuItem(
                              value: 'Conference', child: Text('Conference')),
                          DropdownMenuItem(
                              value: 'Workshop', child: Text('Workshop')),
                          DropdownMenuItem(
                              value: 'Webinar', child: Text('Webinar')),
                        ],
                        onChanged: (value) {
                          eventProvider.filterEvents(value);
                        },
                      ),
                    ),
                    Expanded(
                      child: eventProvider.filteredEvents.isEmpty
                          ? Center(child: Text('No events found'))
                          : ListView.builder(
                              itemCount: eventProvider.filteredEvents.length,
                              itemBuilder: (context, index) {
                                final event =
                                    eventProvider.filteredEvents[index];

                                DateTime eventDate = (event['date']).toDate();

                                String updatedAtText =
                                    event.containsKey('updatedAt') &&
                                            event['updatedAt'] != null
                                        ? (event['updatedAt'] as Timestamp)
                                            .toDate()
                                            .toLocal()
                                            .toString()
                                        : 'Not updated';

                                bool isExpanded =
                                    eventProvider.expandedStates[index] ??
                                        false;
                                bool editMode =
                                    eventProvider.isEditing[index] ?? false;

                                if (editMode) {
                                  return Card(
                                    margin: EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ListTile(
                                          title: TextFormField(
                                            initialValue: event['title'],
                                            decoration: InputDecoration(
                                                labelText: 'Title'),
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
                                                initialValue:
                                                    event['description'],
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
                                                initialValue:
                                                    event['organizer'],
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
                                                      child:
                                                          Text('Conference')),
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
                                                trailing:
                                                    Icon(Icons.calendar_today),
                                                onTap: () => eventProvider
                                                    .selectDate(context, index),
                                              ),
                                              SizedBox(height: 10),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: [
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      eventProvider
                                                          .updateEvent(event);
                                                      eventProvider
                                                          .toggleEditing(
                                                              index, false);
                                                    },
                                                    child: Text('Submit'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      eventProvider
                                                          .toggleEditing(
                                                              index, false);
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
                                  return ExpansionTile(
                                    title: Text(event['title']),
                                    initiallyExpanded: isExpanded,
                                    onExpansionChanged: (value) {
                                      eventProvider.toggleExpandedState(
                                          index, value);
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
                                            Text(
                                                'Location: ${event['location']}'),
                                            Text(
                                                'Organizer: ${event['organizer']}'),
                                            Text(
                                                'Event Type: ${event['eventType']}'),
                                            Text(
                                                'Event Date: ${DateFormat.yMMMd().format(eventDate)}'),
                                            Text(
                                                'Last Updated: $updatedAtText'),
                                            SizedBox(height: 10),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                ElevatedButton(
                                                  onPressed: () {
                                                    eventProvider.toggleEditing(
                                                        index, true);
                                                  },
                                                  child: Text('Edit'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    eventProvider.deleteEvent(
                                                        event['id']);
                                                  },
                                                  child: Text('Delete'),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.red),
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
              Provider.of<EventProvider>(context, listen: false)
                  .notifyListeners();
            }
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
