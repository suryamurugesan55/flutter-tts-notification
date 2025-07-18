import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_tts_notification/Utils/print_utils.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  PrintUtils.printValue('Handling a background message:', '${message.data}');
}

class NotificationService {
  static String? fcmToken;
  static String? refreshFcmToken;
  static late AndroidNotificationChannel _channel;
  static late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  static final _fcm = FirebaseMessaging.instance;
  static final isAndroid = Platform.isAndroid;
  static final isIOS = Platform.isIOS;
  static final FlutterTts flutterTts = FlutterTts();

  static Future<void> init() async {
    await Firebase.initializeApp();
    await _configureAudioSession();
    await _initTts();

    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    if (isAndroid) {
      _channel = const AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
      );

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);
    }

    if (isIOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    try {
      await _fcm.requestPermission(alert: true, badge: true, sound: true);

      fcmToken = await _fcm.getToken();

      PrintUtils.printValue('✅ FCM Token:', '$fcmToken');
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (apnsToken == null) {
        PrintUtils.printValue("❌ APNs token:", "APNs token is NULL");
      } else {
        PrintUtils.printValue("✅ APNs token: ", apnsToken);
      }
    } catch (e) {
      PrintUtils.printValue("❌ Error retrieving FCM token: ", "$e");
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      PrintUtils.printValue('🔁 FCM token refreshed:', newToken);
    });
  }

  static Future<void> _initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5); // Slower rate works better on iOS
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);

    if (Platform.isIOS) {
      // Critical iOS-specific configuration
      await flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playAndRecord,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          IosTextToSpeechAudioCategoryOptions.duckOthers,
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );
      await flutterTts.awaitSpeakCompletion(true);
    }
  }

  static Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(
      AudioSessionConfiguration(
        avAudioSessionCategory:
            Platform.isIOS
                ? AVAudioSessionCategory.playAndRecord
                : AVAudioSessionCategory.playback,
        avAudioSessionMode:
            Platform.isIOS
                ? AVAudioSessionMode.spokenAudio
                : AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions:
            Platform.isIOS
                ? AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation
                : AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunication,
          flags: AndroidAudioFlags.none,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ),
    );
  }

  static Future<void> speakNotification(
    FlutterTts tts,
    String? announceText,
  ) async {
    if (announceText == null || announceText.isEmpty) return;

    try {
      PrintUtils.printValue("Attempting to speak: ", announceText);
      final result = await tts.speak(announceText);
      PrintUtils.printValue("TTS result: ", "$result");
    } catch (e) {
      PrintUtils.printValue("TTS Error: ", "$e");
      if (e is PlatformException) {
        PrintUtils.printValue("Error details: ", "${e.code}, ${e.message}");
      }
    }
  }

  static Future<void> setup() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );

    await _fcm.requestPermission();

    FirebaseMessaging.onMessage.listen(onMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _navigate(message.data),
    );
  }

  static Future<void> onMessage(RemoteMessage message) async {
    final notification = message.notification;
    PrintUtils.printValue('Notification Data:', '${message.data}');
    // Speak the announcement text if available
    if (message.data['announceText'] != null) {
      await speakNotification(flutterTts, message.data['announceText']);
    }
    if (notification != null) {
      showNotification(
        notification,
        jsonEncode(message.data),
        null,
        message.data,
      );
    }
  }

  static void onDidReceiveNotificationResponse(NotificationResponse response) {
    final payload = response.payload ?? '';
    if (response.notificationResponseType ==
        NotificationResponseType.selectedNotification) {
      // Notification tap
      // ignore: unnecessary_null_comparison
      _navigate(payload != null ? json.decode(payload) : {});
    } else if (response.notificationResponseType ==
        NotificationResponseType.selectedNotificationAction) {}
  }

  static void checkInitialMessage() {
    _fcm.getInitialMessage().then((message) => _navigate(message?.data));

    if (isAndroid) {
      _flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails().then(
        getNotificationAppLaunchDetails,
      );
    }
  }

  static FutureOr<void> getNotificationAppLaunchDetails(
    NotificationAppLaunchDetails? value,
  ) {
    final payload = value?.notificationResponse?.payload ?? '';
    if (payload.isNotEmpty) {
      _navigate(json.decode(payload) as Map<String, dynamic>);
    }
  }

  static void _navigate(Map<String, dynamic>? payload) {
    final data = payload;
    if (data != null) {
      // Add you naviagations here based on the payload data
      PrintUtils.printValue('Navigating with data:', '$data');
      // Example: Navigator.pushNamed(context, '/someRoute', arguments: data);
    }
  }

  static void showNotification(
    RemoteNotification notification,
    String? payload,
    String? imagePath,
    Map<String, dynamic> data,
  ) {
    _flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          icon: '@mipmap/ic_launcher',
          styleInformation:
              imagePath != null
                  ? BigPictureStyleInformation(
                    FilePathAndroidBitmap(imagePath),
                    contentTitle: notification.title,
                    summaryText: notification.body,
                  )
                  : null,
          actions: [],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }
}
