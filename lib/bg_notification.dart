import 'package:firebase_database/firebase_database.dart';

Future<void> storeDeviceLocation(String deviceId, double latitude, double longitude) async {
  DatabaseReference locationRef = FirebaseDatabase.instance.ref('device_location/$deviceId');

  try {
    await locationRef.set({
      'latitude': latitude,
      'longitude': longitude,
    });
    print('Device location stored successfully.');
  } catch (e) {
    print('Error storing device location: $e');
  }
}
