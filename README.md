# panda_hub

Event Management Application with Filtering.

## Getting Started

This project was created with Flutter on the frontend and Firebase on the backend.

You need to have an instance of Firestore running locally. Default Firestore emulator port is localhost:8080.

### To test the backend functions locally:

1. Navigate to `/backend/functions/`
2. Run `npm install`
3. Navigate to `/backend/` and run `firebase emulators:start`
4. Go to `/backend/functions/src/index.ts` and replace `req.body` with `req.query`
5. Use the test string provided to create entries in Firestore. Update string as needed to test further.

### To test the frontend:

1. Navigate to `/backend/` and run `firebase emulators:start`
2. Navigate to `/frontend/panda_hub/` and run `flutter pub get` followed by `flutter run -d chrome`

### Screenshots and video:

![List view](https://github.com/maniutin/panda_hub/blob/main/frontend/panda_hub/web/assets/screenshots/list_view.png "List View")
![Filtered List](https://github.com/maniutin/panda_hub/blob/main/frontend/panda_hub/web/assets/screenshots/filtered_list.png "Filtered List")
![Add event view](https://github.com/maniutin/panda_hub/blob/main/frontend/panda_hub/web/assets/screenshots/add_event_view.png "Add Event View")
![Event Details view](https://github.com/maniutin/panda_hub/blob/main/frontend/panda_hub/web/assets/screenshots/event_details.png "Event Details View")
![Edit view](https://github.com/maniutin/panda_hub/blob/main/frontend/panda_hub/web/assets/screenshots/edit_view.png "Edit View")

[Video](https://share.vidyard.com/watch/vZWqPBgYHEsRxMxQgTCVf1?)

## Test Cases

### Backend

#### 1. Firebase Setup

**1.1: Cloud Functions Setup**

Verify if Firebase Cloud Functions are set up correctly and are operational.

**1.2: Firestore Database Setup**

Ensure Firestore is configured and connected to the Firebase project.

#### 2. API Endpoints

**2.1: Successful Event Creation**

Verify that a new event is successfully added to the Firestore database with valid data.

**2.2: Event Creation with Missing Fields**

Event creation should fail with an appropriate error message.

**2.3: Get All Events**

Retrieve all events from Firestore.

**2.4: No Events in Database**

The response should return an empty list.

**2.5: Get Event by ID**

Retrieve a specific event using a valid event ID.

**2.6: Retrieve Event by Invalid ID**

An error message should be returned (e.g., 404 Not Found).

**2.7: Update Event**

Update the details of an existing event and ensure the updatedAt field is updated.

**2.8: Event Update with Invalid Data**

The update should fail, and an appropriate error message should be returned.

**2.9: Delete Event**

The event should be successfully deleted, and a confirmation should be returned.

**2.10: Filter Events by Event Type or Date**

Only events with the appropriate event type should be returned.

## Future considerations:

1. Improvements to UI/UX:

- User-friendly filtering.
- More logical fold/unfold details functionality
- Better visual feedback, less jumpy, better defined edges and boundaries

2. Fully functioning BE/FE interactions
3. Clean up types in Backend
4. Default data to seed
5. Improve error messages for users
