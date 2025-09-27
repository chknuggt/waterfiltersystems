# Firebase Setup Instructions

## Prerequisites
- Firebase account (create one at https://firebase.google.com)
- Flutter SDK installed
- This project opened in your IDE

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Create a project"
3. Enter project name (e.g., "WaterFilterNet")
4. Enable/disable Google Analytics as needed
5. Click "Create project"

## Step 2: Install Firebase CLI

```bash
# For Windows
npm install -g firebase-tools

# For macOS/Linux
npm install -g firebase-tools
# or
curl -sL https://firebase.tools | bash
```

## Step 3: Configure Firebase for Flutter

Run this command in your project root:

```bash
# Login to Firebase
firebase login

# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your Flutter app
flutterfire configure
```

Select:
- Your Firebase project
- Platforms: Android, iOS, Web (as needed)
- This will automatically generate the necessary configuration files

## Step 4: Platform-Specific Setup

### Android
The `flutterfire configure` command should have:
- Created `android/app/google-services.json`
- Updated `android/build.gradle`
- Updated `android/app/build.gradle`

**Minimum SDK Version**: Ensure `android/app/build.gradle` has:
```gradle
android {
    defaultConfig {
        minSdkVersion 21  // or higher
    }
}
```

### iOS
The `flutterfire configure` command should have:
- Created `ios/Runner/GoogleService-Info.plist`
- Updated iOS configuration

Run in `ios/` directory:
```bash
cd ios
pod install
cd ..
```

### Web
The `flutterfire configure` command should have:
- Created `lib/firebase_options.dart`
- Updated `web/index.html` with Firebase configuration

## Step 5: Enable Authentication

1. In Firebase Console, go to your project
2. Click "Authentication" in the left sidebar
3. Click "Get started"
4. Go to "Sign-in method" tab
5. Enable "Email/Password" authentication
6. Click "Enable" and "Save"

## Step 6: Set Up Firestore Database

1. In Firebase Console, click "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" for development
4. Select your preferred location
5. Click "Enable"

## Step 7: Update Security Rules (Important!)

### Firestore Rules
Go to Firestore > Rules and update:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to read/write their own data
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Add other rules as needed
    match /{document=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

### Authentication Rules
These are set automatically when you enable Email/Password auth.

## Step 8: Update Firebase Initialization

Update `lib/main.dart` to use Firebase options:

```dart
import 'firebase_options.dart'; // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const WaterFilterNetApp());
}
```

## Step 9: Test the Setup

1. Run the app:
```bash
flutter run
```

2. Test features:
   - Sign up with a new email/password
   - Sign in with existing credentials
   - Sign out
   - Password reset

## Troubleshooting

### Common Issues:

1. **"No Firebase App" error**:
   - Ensure `flutterfire configure` was run successfully
   - Check that `firebase_options.dart` exists in `lib/`

2. **Authentication not working**:
   - Verify Email/Password is enabled in Firebase Console
   - Check internet connection
   - Ensure correct Firebase project is selected

3. **Firestore permission denied**:
   - Check security rules in Firebase Console
   - Ensure user is authenticated before accessing data

4. **Build errors on Android**:
   - Ensure minSdkVersion is 21 or higher
   - Run `flutter clean` and rebuild

5. **iOS build issues**:
   - Run `cd ios && pod install`
   - Ensure GoogleService-Info.plist is added to Runner

## Next Steps

1. **Production Security Rules**: Update Firestore rules for production
2. **Email Verification**: Add email verification flow
3. **Additional Auth Providers**: Add Google, Apple, Facebook login
4. **User Profile**: Extend user data storage
5. **Error Handling**: Improve error messages and recovery

## Resources

- [FlutterFire Documentation](https://firebase.flutter.dev/docs/overview)
- [Firebase Console](https://console.firebase.google.com)
- [Firebase Auth Documentation](https://firebase.google.com/docs/auth)
- [Cloud Firestore Documentation](https://firebase.google.com/docs/firestore)