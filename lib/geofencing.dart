import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeofencingService {
  static Future<void> startGeofencing() async {
    // Implement geofencing logic here
    // You can use packages like 'geofencing' or 'flutter_geofence' to handle geofencing
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
    String? username, // Make the username parameter nullable
  }) async {
    // Store geofencing data to Firestore
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('Geofences').add({
          'userId': user.uid,
          'username': username, // Use the nullable username here
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
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('Geofences')
            .where('userId', isEqualTo: user.uid)
            .get();
        querySnapshot.docs.forEach((doc) {
          // Extract geofencing data and pass it to onDataReceived callback
          double fenceRadius = doc['fenceRadius'];
          double latitude = doc['latitude'];
          double longitude = doc['longitude'];
          LatLng location = LatLng(latitude, longitude);
          onDataReceived(fenceRadius, location);
        });
      }
    } catch (e) {
      print('Error fetching geofencing data: $e');
    }
  }
}
