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
