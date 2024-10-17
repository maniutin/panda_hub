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

### Screenshots:

![List view](https://github.com/maniutin/panda_hub/blob/main/frontend/panda_hub/web/assets/screenshots/list_view.png "List View")
![Filtered List](https://github.com/maniutin/panda_hub/blob/main/frontend/panda_hub/web/assets/screenshots/filtered_list.png "Filtered List")
![Add event view](https://github.com/maniutin/panda_hub/blob/main/frontend/panda_hub/web/assets/screenshots/add_event_view.png "Add Event View")
![Event Details view](https://github.com/maniutin/panda_hub/blob/main/frontend/panda_hub/web/assets/screenshots/event_details.png "Event Details View")
![Edit view](https://github.com/maniutin/panda_hub/blob/main/frontend/panda_hub/web/assets/screenshots/edit_view.png "Edit View")

[Video](https://share.vidyard.com/watch/vZWqPBgYHEsRxMxQgTCVf1?)

### Future considerations:

1. Improvements to UI/UX:

- User-friendly filtering.
- More logical fold/unfold details functionality
- Better visual feedback, less jumpy, better defined edges and boundaries

2. Fully functioning BE/FE interactions
3. Clean up types in Backend
4. Default data to seed
