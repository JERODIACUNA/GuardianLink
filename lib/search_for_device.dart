import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class SearchForDevicePage extends StatefulWidget {
  final void Function(String? location) onLocationUpdated;

  const SearchForDevicePage({Key? key, required this.onLocationUpdated}) : super(key: key);

  @override
  _SearchForDevicePageState createState() => _SearchForDevicePageState();
}

class _SearchForDevicePageState extends State<SearchForDevicePage> {
  final _deviceIdController = TextEditingController();
  final DatabaseReference _devicePairingRef = FirebaseDatabase.instance.ref('device_pairings');
  final DatabaseReference _deviceLocationRef = FirebaseDatabase.instance.ref('device_location');
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  String _message = '';
  String? _deviceLocation;

  void _pairDevice() async {
    if (_currentUser == null) {
      setState(() {
        _message = 'No user is currently logged in.';
      });
      return;
    }

    final deviceId = _deviceIdController.text.trim();
    if (deviceId.isEmpty) {
      setState(() {
        _message = 'Please enter a device ID.';
      });
      return;
    }

    try {
      final deviceLocationRef = _deviceLocationRef.child(deviceId);
      final locationSnapshot = await deviceLocationRef.get();

      if (locationSnapshot.exists) {
        final devicePairingRef = _devicePairingRef.child(deviceId);

        // Pair device
        await devicePairingRef.child(_currentUser!.uid).set(true);

        // Fetch and display the location
        final latitude = locationSnapshot.child('latitude').value;
        final longitude = locationSnapshot.child('longitude').value;

        final location = 'Location: Latitude $latitude, Longitude $longitude';

        setState(() {
          _message = 'Device paired successfully!';
          _deviceLocation = location;
        });

        // Pass the location to the HomePage
        widget.onLocationUpdated(location);
      } else {
        setState(() {
          _message = 'Device location does not exist. Pairing failed.';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Failed to pair device: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search for Device'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _deviceIdController,
              decoration: const InputDecoration(
                labelText: 'Enter Device ID',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pairDevice,
              child: const Text('Pair Device'),
            ),
            const SizedBox(height: 20),
            Text(
              _message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            if (_deviceLocation != null) // Show the location if available
              Text(
                _deviceLocation!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
