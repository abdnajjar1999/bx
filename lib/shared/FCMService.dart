import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FCMService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initialize() async {
    // Request permissions for iOS/Web
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('User granted permission');
      }

      // Get the current token and save it if user is already logged in
      String? token = await _fcm.getToken();
      if (token != null) {
        await saveTokenToDatabase(token);
      }
    }

    // Listen for auth state changes to save token when user logs in
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        String? token = await _fcm.getToken();
        if (token != null) {
          await saveTokenToDatabase(token);
        }
      }
    });

    // Listen for token refreshes
    _fcm.onTokenRefresh.listen(saveTokenToDatabase);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
      }

      if (message.notification != null) {
        if (kDebugMode) {
          print(
              'Message also contained a notification: ${message.notification}');
        }
      }
    });
  }

  Future<void> saveTokenToDatabase(String token) async {
    User? user = _auth.currentUser;
    if (user != null) {
      // We save the token in a general 'userTokens' collection or directly in user profile
      // Saving it in a centralized place is often better for Cloud Functions
      await _firestore.collection('userTokens').doc(user.uid).set({
        'fcmToken': token,
        'lastUpdated': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'email': user.email,
      }, SetOptions(merge: true));

      if (kDebugMode) {
        print('FCM Token saved to database');
      }
    }
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    // If you're going to use other Firebase services in the background,
    // such as Firestore, make sure you call `Firebase.initializeApp()` first.
    if (kDebugMode) {
      print("Handling a background message: ${message.messageId}");
    }
  }
}
