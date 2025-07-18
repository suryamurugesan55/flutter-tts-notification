# Flutter TTS Notification with Firebase

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-039BE5?style=for-the-badge&logo=Firebase&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)

A complete implementation of Text-to-Speech (TTS) notifications in Flutter using Firebase Cloud Messaging (FCM), with support for both foreground and background notifications.

## 📱 Features

- 🔔 Firebase Cloud Messaging integration
- 🗣️ Text-to-Speech notification announcements
- 📲 Cross-platform support (Android & iOS)
- 🎚️ Customizable TTS parameters (speed, pitch, volume)
- 🎧 Proper audio session management
- 📊 Notification analytics logging
- 🎨 Beautiful animated UI

## ⚠️ Important iOS Limitations

**Automatic TTS from background notifications does not work on iOS** due to platform restrictions:

- 🎙️ TTS only works when app is in foreground
- 🔕 Background notifications show silently (no auto-speech)
- 👆 User must tap notification to open app for TTS playback

This is an iOS platform limitation that cannot be bypassed as Apple doesn't allow background audio playback from notifications.

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (v3.0.0 or later)
- Firebase project
- Physical device recommended (emulators have limited FCM support)

### 📥 Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/suryamurugesan55/flutter-tts-notification.git
   cd flutter-tts-notification
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

### 🔥 Firebase Setup

#### For Android:

1. Create Android app in Firebase Console
2. Download `google-services.json`
3. Place it in `android/app/`

#### For iOS:

1. Create iOS app in Firebase Console
2. Download `GoogleService-Info.plist`
3. Place it in `ios/Runner/`
4. Enable capabilities in Xcode:
   - Push Notifications
   - Background Modes (Audio, Remote notifications)

### 📦 Dependencies

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^2.24.1
  firebase_messaging: ^14.7.0
  flutter_tts: ^3.6.3
  flutter_local_notifications: ^15.1.1
  audio_session: ^0.1.15
```

### ⚙️ Platform-Specific Configuration

#### iOS (`ios/Runner/Info.plist`)

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>remote-notification</string>
</array>

<key>NSMicrophoneUsageDescription</key>
<string>For text-to-speech functionality</string>
```

#### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

## 🛠️ Usage

### Initialization

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.init();
  runApp(const MyApp());
}
```

### Sending Test Notifications

Use this payload format:

```json
{
  "notification": {
    "title": "Test Notification",
    "body": "This appears in notification tray"
  },
  "data": {
    "announceText": "This will be spoken by TTS",
    "customData": "your_data_here"
  }
}
```

### Manual Testing

The app includes a test button that:

1. Speaks a sample announcement
2. Shows a local notification
3. Prints debug information

## 🧩 Project Structure

```
lib/
├── main.dart          # App entry point
├── screens/
│   └── home_page.dart # Main UI screen
└── services/
    └── notification_service.dart # All notification logic
```

## 🌐 API Reference

### `NotificationService` Methods

| Method                | Description                  |
| --------------------- | ---------------------------- |
| `init()`              | Initialize FCM and TTS       |
| `setup()`             | Set up notification handlers |
| `speakNotification()` | Trigger TTS announcement     |
| `showNotification()`  | Display local notification   |

## 🐛 Troubleshooting

### Common Issues

**Notifications not arriving:**

- Verify FCM token is registered (`PrintUtils` shows this)
- Check internet connection
- Ensure proper Firebase configuration files

**TTS not working on iOS:**

- Remember foreground-only limitation
- Check microphone permissions
- Review audio session configuration

**Android notifications not showing:**

- Verify notification channel is created
- Check for proper launcher icon

## 📝 Notes

- For production, consider adding notification analytics
- Implement a proper error handling system
- Add localization for TTS language selection

## 🤝 Contributing

Pull requests are welcome! For major changes, please open an issue first.
