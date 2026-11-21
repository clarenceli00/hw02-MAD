# hw02

## Spice 2: security rules tests

From the project root in PowerShell:

```powershell
npm.cmd install --ignore-scripts
firebase emulators:start --only "auth,firestore" --project hw02-2236a
```

Restart any previously running Firebase emulators so they load `firestore.rules`
through `firebase.json`. In a second terminal:

```powershell
npm.cmd run test:rules
```

The six tests cover signed-out reads, cross-user edits/deletes, forged authors,
valid author CRUD, immutable ownership/creation dates, and private profiles.
Tests use the isolated local project `demo-hw02-rules-tests` and clear only that
test namespace, leaving app demo records in `hw02-2236a` alone. The emulator may
print a multiple-project warning for this intentional test namespace.
Tests never connect to production. Capture your passing output for evidence;
permission-denied messages from deliberately rejected requests are expected.
No production rules are deployed by these commands.

## Spice 4: duplicate-post test in the actual Flutter app

With the emulators running, fully stop the app and run on your Android emulator:

```powershell
flutter run --dart-define=USE_EMULATORS=true --dart-define=TEST_DUPLICATE_POSTS=true
```

Register/sign in, type a distinctive message, and press Post once. In this test
mode the app deliberately calls the real `BoardService.postMessage` twice
concurrently with the same document ID. Look for `Spice 4: two calls completed`
in the Flutter terminal; it includes the document ID. In the Emulator UI at
http://127.0.0.1:4000/firestore, select project `hw02-2236a` and verify there is
exactly one document for that message and ID. Capture the terminal and database
result. Post another distinct message to verify a genuinely new post gets a new ID.

The service uses a Firestore transaction: an existing matching post is a no-op,
and a conflicting payload/author for that ID is rejected. An unchanged draft
retains its ID after an unsuccessful write so retrying does not duplicate it.
Transactions require connectivity. Draft IDs are held in memory; they do not
survive an app restart. This is not a permanent deduplication log after deletion.

Return to ordinary emulator posting by restarting with only:

```powershell
flutter run --dart-define=USE_EMULATORS=true
```

The duplicate test flag has no effect unless emulator mode is also enabled.
Record actual expected/observed results and pass/fail; these instructions are
not a claim that you have completed the evidence requirements.

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
