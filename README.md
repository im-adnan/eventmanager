# Event Manager App

A Flutter-based Contact & Event Management application with real-time features, secure authentication, and calendar integration.

## Features

- Google & Apple Sign-In Authentication
- Contact Management with secure storage
- Google Calendar Integration
- Real-time Chat using Firebase Cloud Messaging
- BLoC Pattern for State Management
- Offline Support with SQLite
- Push Notifications

## Prerequisites

- Flutter SDK (^3.7.2)
- Firebase Account and Project Setup
- Google Cloud Project with Calendar API enabled
- Apple Developer Account (for iOS deployment)

## Setup Instructions

### 1. Flutter Setup

```bash
# Clone the repository
git clone [repository-url]
cd eventmanager

# Install dependencies
flutter pub get
```

### 2. Firebase Setup

1. Create a new Firebase project
2. Add Android & iOS apps in Firebase console
3. Download and add configuration files:
   - `google-services.json` for Android
   - `GoogleService-Info.plist` for iOS
4. Enable Authentication methods:
   - Google Sign-In
   - Apple Sign-In
5. Set up Cloud Firestore

### 3. Google Calendar API Setup

1. Enable Google Calendar API in Google Cloud Console
2. Create OAuth 2.0 credentials
3. Add the credentials to the app

### 4. Environment Setup

Create a `.env` file in the project root:

```
GOOGLE_CLIENT_ID=your_client_id
GOOGLE_CLIENT_SECRET=your_client_secret
```

## Project Structure

```
lib/
├── bloc/          # BLoC pattern implementations
├── models/        # Data models
├── repositories/  # Data repositories
├── screens/       # UI screens
├── services/      # External services
├── utils/         # Utility functions
└── widgets/       # Reusable widgets
```

## Running the App

```bash
# Debug mode
flutter run

# Release mode
flutter run --release
```

## Deployment

### iOS (TestFlight)

1. Configure signing in Xcode
2. Build the app archive
3. Upload to App Store Connect
4. Submit for TestFlight

### Android (Play Store)

1. Configure signing
2. Build release APK/Bundle
3. Upload to Play Console
4. Submit for review

## Security

- All sensitive data is encrypted using AES encryption
- Secure storage for API keys and tokens
- Firebase Security Rules implementation
- SSL pinning for network requests

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
