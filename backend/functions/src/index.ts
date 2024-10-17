const { functions, logger } = require("firebase-functions");
const { onRequest } = require("firebase-functions/v2/https");
const {
  onDocumentCreated,
  onDocumentWritten,
  Change,
  FirestoreEvent,
} = require("firebase-functions/v2/firestore");

const {
  admin,
  initializeApp,
  applicationDefault,
  cert,
} = require("firebase-admin/app");

const {
  getFirestore,
  Timestamp,
  FieldValue,
  Filter,
} = require("firebase-admin/firestore");

initializeApp();

const db = getFirestore();
db.settings({ ignoreUndefinedProperties: true });

// Get all events
exports.getAllEvents = onRequest(async (req: any, res: any) => {
  // TODO: cleanup types

  try {
    const eventsSnapshot = await db.collection("events").get();
    const events = eventsSnapshot.docs.map((doc: any) => ({
      id: doc.id,
      ...doc.data(),
    })); // TODO: cleanup types

    res.status(200).json(events);
  } catch (error) {
    res.status(500).send(error);
  }
});

// Get an event by ID
exports.getEventById = onRequest(async (req: any, res: any) => {
  // TODO: cleanup types
  const { id } = req.query; // change req.query to req.body when sending req from client
  try {
    const doc = await db.collection("events").doc(id).get();
    if (!doc.exists) {
      return res.status(404).send("Event not found");
    }
    res.status(200).json({ id: doc.id, ...doc.data() });
  } catch (error) {
    res.status(500).send(error);
  }
});

// Add a new event
// example string: http://127.0.0.1:5001/panda-hub-a4da9/us-central1/createEvent?title=Event%20Title&description=Event%20Description&location=Event%20Location&organizer=Event%20Organizer&eventType=Event%20Type&date=2024-12-25
exports.createEvent = onRequest(async (req: any, res: any) => {
  // TODO: cleanup types
  const { title, description, date, location, organizer, eventType } = req.body;
  try {
    const event = {
      title,
      description,
      date: Timestamp.fromDate(new Date(date)),
      location,
      organizer,
      eventType,
      updatedAt: FieldValue.serverTimestamp(),
    };

    const docRef = await db.collection("events").add(event);
    res.json({ result: `Message with ID: ${docRef.id} added.` });
  } catch (error) {
    res.status(500).send(error);
  }
});

// Update an event
exports.updateEvent = onRequest(async (req: any, res: any) => {
  // TODO: cleanup types
  const { id, title, description, date, location, organizer, eventType } =
    req.body;

  try {
    const updatedEvent = {
      title,
      description,
      date: Timestamp.fromDate(new Date(date)),
      location,
      organizer,
      eventType,
      updatedAt: FieldValue.serverTimestamp(),
    };
    await db.collection("events").doc(id).update(updatedEvent);
    res.status(200).send("Event updated successfully");
  } catch (error) {
    res.status(500).send(error);
  }
});

// Delete an event
exports.deleteEvent = onRequest(async (req: any, res: any) => {
  // TODO: cleanup types

  const { id } = req.body;
  try {
    await db.collection("events").doc(id).delete();
    res.status(200).send("Event deleted successfully");
  } catch (error) {
    res.status(500).send(error);
  }
});
