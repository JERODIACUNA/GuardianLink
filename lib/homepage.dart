import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:GuardianLink/edit_profile.dart';
import 'package:GuardianLink/login_screen.dart';
import 'package:GuardianLink/notification_page.dart';
import 'package:GuardianLink/search_for_device.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedCategory = ''; // Track the selected category
  String defaultUsername = '';
  String defaultEmail = '';
  late LatLng _initialCameraPosition =
      LatLng(0, 0); // Initialize with default value
  late Position _currentPosition;
  late GoogleMapController _mapController; // Google Map Controller

  @override
  void initState() {
    super.initState();
    // Call methods to fetch the logged-in user's information and check location permission
    fetchUserData();
    fetchUsername();
    _checkLocationPermission();
  }

  void fetchUserData() async {
    // Retrieve the current user from Firebase Authentication
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // If the user is not null, update defaultEmail with user's email
      setState(() {
        defaultEmail = user.email ?? ''; // Assign the user's email
      });
    }
  }

  void fetchUsername() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Access Firestore collection to retrieve the user's name
      DocumentSnapshot<Map<String, dynamic>> userData = await FirebaseFirestore
          .instance
          .collection('Caregivers')
          .doc(user.uid)
          .get();

      if (userData.exists) {
        setState(() {
          defaultUsername = userData['name']; // Update defaultUsername
        });
      }
    }
  }

  void _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false, // This removes all the routes from the stack
      );
    } catch (e) {
      print(e);
      // Handle sign-out failure
      // You can show an error message to the user here if needed
    }
  }

  void updateUsername(String newUsername) {
    setState(() {
      defaultUsername = newUsername;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.withOpacity(1),
        centerTitle: true,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu_open),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: Builder(
          builder: (BuildContext context) {
            return Text('Welcome, $defaultUsername');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Implement navigation to the notifications page
              _navigateToNotifications(context);
            },
          ),
          IconButton(
            icon: const CircleAvatar(
              radius: 20, // Set the radius to the desired size
              backgroundImage:
                  AssetImage('lib/assets/logo.png'), // Provide the image path
            ),
            onPressed: () {
              // Implement navigation to the account page
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                defaultUsername,
              ),
              accountEmail: Text(
                defaultEmail,
              ),
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundImage: AssetImage('lib/assets/logo.png'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.search_sharp),
              title: const Text(
                'Search for Device',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SearchForDevicePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfilePage(
                      updateUsername: updateUsername,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text(
                'About Us',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () => _signOut(context),
            ),
          ],
        ),
      ),
      body: _initialCameraPosition.latitude == 0 &&
              _initialCameraPosition.longitude == 0
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialCameraPosition,
                zoom: 14,
              ),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              myLocationEnabled: true, // Show user's current location
              myLocationButtonEnabled:
                  true, // Enable button to center camera on user's location
              markers: {
                Marker(
                  markerId: MarkerId('currentLocation'),
                  position: _initialCameraPosition,
                  infoWindow: InfoWindow(
                    title: 'Current Location',
                  ),
                ),
              },
            ),
    );
  }

  // Function to navigate to the notifications page
  void _navigateToNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NotificationPage()),
    );
  }

  Future<void> _checkLocationPermission() async {
    final PermissionStatus permissionStatus = await Permission.location.status;
    if (permissionStatus == PermissionStatus.granted) {
      _getCurrentLocation();
    } else {
      final PermissionStatus newPermissionStatus =
          await Permission.location.request();
      if (newPermissionStatus == PermissionStatus.granted) {
        _getCurrentLocation();
      } else {
        print('Location permission denied.');
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
        _initialCameraPosition = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print(e);
    }
  }
}
