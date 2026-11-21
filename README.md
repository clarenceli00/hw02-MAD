# Message Board

A Flutter message board with Firebase email/password authentication, private user profiles, and live messages. Signed-in users can post messages and edit or delete their own posts.

## Requirements

- Flutter with Dart 3.13.2 or a compatible Dart 3.x version.
- Android Studio and the Android SDK, with an Android emulator or connected device.
- A Firebase project with Authentication and Cloud Firestore.
- Node.js/npm for the Firebase CLI.

## Install dependencies

From the project root:

```powershell
flutter pub get
```

## Configure Firebase

1. Create a Firebase project, enable Email/Password under Authentication, and create a Cloud Firestore database.
2. Install and sign in to the Firebase CLI, then install FlutterFire CLI:

   ```powershell
   npm.cmd install -g firebase-tools
   firebase login
   dart pub global activate flutterfire_cli
   ```

3. Generate configuration for your Firebase project:

   ```powershell
   dart pub global run flutterfire_cli:flutterfire configure --project YOUR_PROJECT_ID --platforms android
   ```

   Use `com.example.hw02` as the Android package name when registering the existing app. Configuration generates `lib/firebase_options.dart` and the Android Firebase configuration. `lib/firebase_options.dart` is excluded from Git and must be generated on a fresh checkout.

4. Deploy this repository's database rules to your chosen project:

   ```powershell
   firebase deploy --only firestore:rules --project YOUR_PROJECT_ID
   ```

The checked-in `.firebaserc` references the original development project. Use explicit `--project YOUR_PROJECT_ID` arguments when configuring your own project.

## Run the app

Start an Android emulator or connect an Android device, then run:

```powershell
flutter devices
flutter run
```

Normal runs connect to the Firebase project in `lib/firebase_options.dart`. The splash screen initializes Firebase, then the app opens login or the signed-in view. Registration collects first name, last name, role, email, and password. An incomplete profile must be completed before opening the board.

The signed-in view contains Messages and My Profile tabs, plus Sign Out. Posting uses a transaction to avoid creating the same post twice when an unchanged draft is retried. Posting requires a network connection.

## Run with local Firebase emulators

The Firebase emulators also require a compatible Java installation. Start Authentication and Firestore locally:

```powershell
firebase emulators:start --only "auth,firestore" --project YOUR_PROJECT_ID
```

Use the same project ID as the generated app configuration. Keep this terminal open. In a second terminal:

```powershell
flutter run --dart-define=USE_EMULATORS=true
```

The app uses ports 9099 for Authentication and 8080 for Firestore. It connects through `10.0.2.2` on an Android emulator and `127.0.0.1` on desktop/web. The Emulator UI address is printed by the Firebase CLI, normally http://127.0.0.1:4000.

For a different reachable host, pass `--dart-define=EMULATOR_HOST=HOST_ADDRESS`. Physical devices require additional network access configuration. The included Android debug network configuration permits HTTP to local emulator addresses.

Fully stop and restart the app when switching between local emulators and the hosted Firebase project. Local accounts and records are separate from hosted Firebase data.

## Data layout

- `users/{uid}`: UID, first name, last name, role, and server-generated registration datetime. Each user can access only their own profile. The role is descriptive profile data, not an administrative permission.
- `messages/{messageId}`: text, author UID/name, creation timestamp, and optional edit timestamp. Signed-in users can read messages; rules restrict creation to the signed-in author and edits/deletes to the owner.

Firebase calls are kept in `AuthService`, `UserRecordService`, and `BoardService`. The board receives typed messages through a live stream.
