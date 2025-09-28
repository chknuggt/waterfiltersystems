# 🌊 WaterFilterNet - Water Filter Service Management App

**WaterFilterNet** is a comprehensive Flutter application designed for water filtration service companies in Cyprus. The app specializes in managing installation and servicing of water filters, water softeners, and tank cleaning for residential and commercial customers.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-039BE5?style=for-the-badge&logo=Firebase&logoColor=white)
![Stripe](https://img.shields.io/badge/Stripe-626CD9?style=for-the-badge&logo=Stripe&logoColor=white)

## 📱 Features

### ✅ Currently Implemented
- **Authentication System** - Firebase Auth with email/password + demo mode
- **E-Commerce Shop** - Full WooCommerce integration with product catalog
- **Payment Processing** - Stripe integration with card management
- **QR Code Scanning** - For filter registration and product discovery
- **Admin Management** - Firebase Custom Claims-based admin system
- **Service Management** - Models for tracking filter systems and service requests
- **Address Management** - Customer shipping addresses with validation

### 🔄 In Development
- QR code to filter registration flow
- Service calendar booking system
- Push notifications
- Real-time booking approval

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (^3.7.0)
- Firebase account
- Node.js (for admin scripts)
- Stripe account (for payments)

### Setup Files Required
You need these **4 critical files** (transfer from secure location):

1. **`.env`** - Environment variables (API keys, configuration)
2. **`scripts/firebase-admin-key.json`** - Firebase service account
3. **`lib/firebase_options.dart`** - Firebase project configuration
4. **`android/app/google-services.json`** - Firebase Android configuration

### Installation

1. **Clone repository:**
   ```bash
   git clone <your-repository-url>
   cd WaterFilterNetApp-main
   ```

2. **Transfer secret files** (see Setup Files Required above)

3. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

4. **Install admin script dependencies:**
   ```bash
   cd scripts
   npm install
   cd ..
   ```

5. **Run the app:**
   ```bash
   flutter run -d chrome --web-hostname 0.0.0.0 --web-port 8080
   ```

## 🔧 Configuration

### Environment Variables (.env)

Copy `.env.example` to `.env` and configure:

```env
# Stripe API Keys (Required for payments)
STRIPE_PUBLISHABLE_KEY_WEB=pk_test_your_web_key
STRIPE_PUBLISHABLE_KEY_MOBILE=pk_test_your_mobile_key
STRIPE_SECRET_KEY=sk_test_your_secret_key

# WooCommerce API (Optional)
WOOCOMMERCE_URL=https://your-store.com/wp-json/wc/v3
WOOCOMMERCE_CONSUMER_KEY=ck_your_consumer_key
WOOCOMMERCE_CONSUMER_SECRET=cs_your_consumer_secret

# Business Configuration
FREE_SHIPPING_THRESHOLD=75.0
DEFAULT_CURRENCY=EUR
DEFAULT_COUNTRY=CY
```

### Firebase Setup

1. **Create Firebase project:**
   - Go to [Firebase Console](https://console.firebase.google.com)
   - Create new project
   - Enable Authentication (Email/Password)
   - Create Firestore database (test mode)

2. **Configure Flutter:**
   ```bash
   # Install Firebase CLI
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli

   # Login and configure
   firebase login
   flutterfire configure
   ```

3. **Update main.dart:**
   ```dart
   import 'firebase_options.dart';

   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
   ```

### Security Rules

Update Firestore rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /{document=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## 👨‍💼 Admin Management

### Professional Admin System
Uses **Firebase Custom Claims** - the same approach used by Shopify, Stripe, and AWS:

- ✅ **Secure**: Admin roles assigned server-side only
- ✅ **Fast**: No database reads needed for role checks
- ✅ **Professional**: Industry-standard pattern
- ✅ **Multi-tenant**: Each deployment has own admins

### Setup First Admin

1. **User signs up normally:**
   ```
   Email: mariosano333@gmail.com
   Password: (chosen by user)
   ```

2. **Get Firebase Admin SDK key:**
   - Firebase Console > Project Settings > Service Accounts
   - Generate new private key
   - Save as `scripts/firebase-admin-key.json`

3. **Make them admin:**
   ```bash
   cd scripts
   npm install
   node admin-manager.js add-admin mariosano333@gmail.com
   ```

4. **Verify setup:**
   ```bash
   node admin-manager.js check-admin mariosano333@gmail.com
   ```

### Admin Commands

```bash
# Add admin role
node admin-manager.js add-admin email@domain.com

# Remove admin role
node admin-manager.js remove-admin email@domain.com

# List all admins
node admin-manager.js list-admins

# Check admin status
node admin-manager.js check-admin email@domain.com

# Show help
node admin-manager.js help
```

### Admin Features
- **Settings Access**: Change email & password with security validation
- **Admin Dashboard**: Access to `/admin` routes for service management
- **Debug Tools**: Token refresh, claims debugging, force logout

## 🏗️ Architecture

### Tech Stack
- **Framework**: Flutter (Cross-platform mobile and web)
- **State Management**: Provider pattern
- **Backend**: Firebase (Auth, Firestore, Storage)
- **Payments**: Stripe integration
- **E-commerce**: WooCommerce API
- **QR Scanning**: mobile_scanner package
- **Notifications**: flutter_local_notifications

### Project Structure
```
lib/
├── config/              # App configuration
├── core/               # Core components (guards, navigation, theme)
├── models/             # Data models (User, ServiceProfile, etc.)
├── providers/          # State management
├── screens/            # UI screens
│   ├── admin/         # Admin dashboard (web-only)
│   ├── auth/          # Authentication
│   ├── main_tabs/     # Main navigation
│   └── checkout/      # Payment flow
├── services/           # Business logic & APIs
├── utils/             # Utility functions
└── widgets/           # Reusable UI components
```

### Service Models

**ServiceProfile** - Tracks filter systems:
```dart
{
  "userId": "user123",
  "qrCodeId": "WFN-2024-001234",
  "system": {
    "brand": "AquaPure",
    "model": "RO-5",
    "components": [
      {
        "type": "sediment",
        "intervalDays": 180,
        "lastChangedAt": "2024-01-01T00:00:00Z"
      }
    ]
  }
}
```

**ServiceRequest** - Manages bookings:
```dart
{
  "userId": "user123",
  "type": "filterChange",
  "status": "pending",
  "priority": "normal",
  "preferredSchedule": {
    "preferredDate": "2024-07-15T00:00:00Z",
    "preferredTimeSlot": "09:00-12:00"
  }
}
```

## 🛠️ Development

### Demo Mode
For development without full setup:
```
Demo credentials: demo@waterfilternet.com / demo123
Admin credentials: admin@waterfilternet.com / admin123
```

### Working Hours (Cyprus Time)
- **Monday-Tuesday, Thursday-Friday**: 7:00 AM - 4:00 PM
- **Wednesday, Saturday**: 7:00 AM - 1:00 PM
- **Sunday**: Closed

### Service Intervals
- **Sediment/Carbon Filters**: 6 months (180 days)
- **RO Membranes**: 2 years (730 days)
- **Mineralizers**: 1 year (365 days)
- **CO₂ Cartridges**: 3 months (90 days)

### Commands
```bash
# Development
flutter run -d chrome --web-hostname 0.0.0.0 --web-port 8080

# Build
flutter build web --release
flutter build apk --release

# Test
flutter test
flutter analyze
```

## 🔐 Security

### Secure Files (Never Commit)
- `.env` - API keys and configuration
- `scripts/firebase-admin-key.json` - Firebase service account
- `lib/firebase_options.dart` - Firebase configuration
- `android/app/google-services.json` - Firebase Android config

### Best Practices
- All sensitive data in environment variables
- Firebase Custom Claims for role management
- Stripe tokenization for payment security
- API key restrictions in Google Cloud Console
- Secure file transfer for multi-computer development

## 🚀 Deployment

### Mobile
- **Android**: Google Play Store
- **iOS**: Apple App Store

### Web Admin
- **URL**: `https://waterfilternet.com/admin`
- **Hosting**: Firebase Hosting
- **Access**: Desktop/tablet optimized

### Environment
```dart
// Production
const String ENVIRONMENT = "production";
const String FIREBASE_PROJECT = "waterfilternet-cyprus";
```

## 🧪 Testing

### Verification Checklist
- [ ] All 4 secret files transferred
- [ ] `flutter pub get` completed
- [ ] `npm install` in scripts/ completed
- [ ] Admin script shows admin status as YES
- [ ] App runs without errors
- [ ] Admin login works and shows Admin Tools
- [ ] Admin Dashboard accessible at `/admin`

### Testing Flows
1. **Authentication**: Sign up, login, password reset
2. **E-commerce**: Browse products, add to cart, checkout
3. **Admin Access**: Login as admin, access dashboard
4. **QR Scanning**: Scan codes for registration
5. **Service Booking**: Request service, select times

## 🐛 Troubleshooting

### Common Issues

**"No such file or directory: .env"**
- Copy `.env` from secure location to project root

**"Firebase not configured"**
- Ensure `lib/firebase_options.dart` and `android/app/google-services.json` exist
- Run `flutterfire configure` if needed

**"firebase-admin-key.json not found"**
- Copy file to `scripts/firebase-admin-key.json`
- Check permissions: `chmod 600 scripts/firebase-admin-key.json`

**"No admin access found"**
- Use admin script: `node admin-manager.js check-admin email@domain.com`
- Logout/login to refresh token
- Use debug tools in Settings

**"Stripe not configured"**
- Check `.env` file has valid Stripe keys
- Verify keys in Stripe Dashboard

## 📞 Support

### Development Team
- **Flutter Development**: Claude Code Assistant
- **Backend**: Firebase/Firestore
- **Design**: Material Design 3

### Resources
- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Stripe Documentation](https://stripe.com/docs)
- [WooCommerce API](https://woocommerce.github.io/woocommerce-rest-api-docs/)

## 📄 License

This project is proprietary software for WaterFilterNet Cyprus. All rights reserved.

---

*This comprehensive documentation covers all aspects of the WaterFilterNet service management application, from initial setup to production deployment.*