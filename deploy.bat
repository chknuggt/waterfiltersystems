@echo off
echo ==========================================
echo   WaterFilterNet Production Deployment
echo ==========================================

echo.
echo 1. Building Flutter app for production...
flutter clean
flutter pub get
flutter build web --release

echo.
echo 2. Deploying Firestore rules...
firebase deploy --only firestore:rules

echo.
echo 3. Deploying Firestore indexes...
firebase deploy --only firestore:indexes

echo.
echo 4. Deploying to Firebase Hosting...
firebase deploy --only hosting

echo.
echo ==========================================
echo   Deployment Complete!
echo ==========================================
echo.
echo Your app is now available at:
echo https://waterfilternet-82513.web.app
echo.
pause