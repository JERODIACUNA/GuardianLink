import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class EditDeviceLocationPage extends StatefulWidget {
  @override
  _EditDeviceLocationPageState createState() => _EditDeviceLocationPageState();
}

class _EditDeviceLocationPageState extends State<EditDeviceLocationPage> {
  final DatabaseReference _deviceLocationRef = FirebaseDatabase.instance.ref('device_location');
  final TextEditingController _deviceIdController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  void _updateLocation() async {
    final deviceId = _deviceIdController.text;
    final latitude = double.tryParse(_latitudeController.text);
    final longitude = double.tryParse(_longitudeController.text);

    if (deviceId.isNotEmpty && latitude != null && longitude != null) {
      try {
        await _deviceLocationRef.child(deviceId).set({
          'latitude': latitude,
          'longitude': longitude,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location updated for device $deviceId')),
        );
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update location')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter valid device ID, latitude, and longitude')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Device Location'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _deviceIdController,
              decoration: InputDecoration(labelText: 'Device ID'),
            ),
            TextField(
              controller: _latitudeController,
              decoration: InputDecoration(labelText: 'Latitude'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: _longitudeController,
              decoration: InputDecoration(labelText: 'Longitude'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateLocation,
              child: Text('Update Location'),
            ),
          ],
        ),
      ),
    );
  }
}
