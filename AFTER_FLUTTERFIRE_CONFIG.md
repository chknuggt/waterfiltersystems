# After Running flutterfire configure

Once you've successfully run `flutterfire configure`, you need to update main.dart:

## Step 1: Update lib/main.dart

Replace the import line:
```dart
// import 'firebase_options.dart'; // Uncomment this after running flutterfire configure
```

With:
```dart
import 'firebase_options.dart';
```

## Step 2: Update Firebase initialization

Replace:
```dart
await Firebase.initializeApp();
// After running flutterfire configure, change this to:
// await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

With:
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

## Step 3: Enable Authentication in Firebase Console

1. Go to https://console.firebase.google.com
2. Select your project
3. Click "Authentication" → "Get started"
4. Go to "Sign-in method" tab
5. Enable "Email/Password" authentication

## Step 4: Set up Firestore Database

1. In Firebase Console, click "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode"
4. Select a location close to you

## Step 5: Test Your App

Run `flutter run` and test:
- Sign up with a new account
- Sign in with existing credentials
- The authentication should now work properly!

## If you get permission errors:

Update Firestore security rules to:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```