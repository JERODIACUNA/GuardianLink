import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';

class GeofencingService {
  static Future<void> startGeofencing() async {
    await Firebase.initializeApp();
    Workmanager().initialize(callbackDispatcher, isInDebugMode: false); // Changed to false
    Workmanager().registerPeriodicTask(
      "1",
      "geofenceCheck",
      frequency: const Duration(minutes: 15),
    );
  }

  static Future<String?> fetchUsername() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot<Map<String, dynamic>> userData =
            await FirebaseFirestore.instance
                .collection('Caregivers')
                .doc(user.uid)
                .get();

        if (userData.exists) {
          return userData['name'];
        }
      }
    } catch (e) {
      print('Error fetching username: $e');
    }
    return null; // Return null if user or name not found or if an error occurs
  }

  static Future<void> storeGeofencingData({
    required double fenceRadius,
    required LatLng selectedLocation,
    String? username,
  }) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentReference docRef = FirebaseFirestore.instance
            .collection('Geofences')
            .doc(user.uid); // Use user ID as document ID

        await docRef.set({
          'username': username,
          'fenceRadius': fenceRadius,
          'latitude': selectedLocation.latitude,
          'longitude': selectedLocation.longitude,
        });
        print('Geofencing data stored successfully.');
      }
    } catch (e) {
      print('Error storing geofencing data: $e');
    }
  }

  static Future<void> fetchGeofencingData({
    required Function(double fenceRadius, LatLng selectedLocation)
        onDataReceived,
  }) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('Geofences')
            .doc(user.uid) // Use user ID as document ID
            .get();

        if (doc.exists) {
          double fenceRadius = doc['fenceRadius'];
          double latitude = doc['latitude'];
          double longitude = doc['longitude'];
          LatLng location = LatLng(latitude, longitude);
          onDataReceived(fenceRadius, location);
        } else {
          print('No geofencing data found for user.');
        }
      }
    } catch (e) {
      print('Error fetching geofencing data: $e');
    }
  }

  static Future<void> checkGeofenceAndSendNotification() async {
    try {
      // Fetch device location from Realtime Database
      DatabaseReference locationRef =
          FirebaseDatabase.instance.ref('device_location');
      DataSnapshot locationSnapshot = await locationRef.get();

      double deviceLatitude = locationSnapshot.child('latitude').value as double;
      double deviceLongitude =
          locationSnapshot.child('longitude').value as double;

      // Fetch geofence data from Firestore
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('Geofences')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          double fenceRadius = doc['fenceRadius'];
          double latitude = doc['latitude'];
          double longitude = doc['longitude'];

          double distance = calculateDistance(
            latitude,
            longitude,
            deviceLatitude,
            deviceLongitude,
          );

          if (distance > fenceRadius) {
            // Device is outside the geofence, send a notification
            FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
                FlutterLocalNotificationsPlugin();

            const AndroidInitializationSettings initializationSettingsAndroid =
                AndroidInitializationSettings('@mipmap/ic_launcher');
            const InitializationSettings initializationSettings =
                InitializationSettings(
              android: initializationSettingsAndroid,
            );
            await flutterLocalNotificationsPlugin.initialize(
                initializationSettings);

            var androidPlatformChannelSpecifics = AndroidNotificationDetails(
                'geofence_channel_id', 'Geofence Notifications',
                channelDescription: 'Notifications for geofence alerts',
                importance: Importance.max,
                priority: Priority.high,
                ticker: 'ticker');
            var platformChannelSpecifics =
                NotificationDetails(android: androidPlatformChannelSpecifics);
            await flutterLocalNotificationsPlugin.show(
                0,
                'Geofence Alert',
                'You are outside the geofence!',
                platformChannelSpecifics,
                payload: 'geofence_alert');
          }
        }
      }
    } catch (e) {
      print('Error checking geofence: $e');
    }
  }

  static double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000; // Distance in meters
  }

  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      await Firebase.initializeApp();
      await checkGeofenceAndSendNotification();
      return Future.value(true);
    });
  }
}
