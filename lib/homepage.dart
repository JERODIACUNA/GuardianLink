import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:p4/edit_profile.dart';
import 'package:p4/login_screen.dart';
import 'package:p4/search_for_device.dart';
import 'package:p4/notification_page.dart';

import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const HomePage());
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedCategory = ''; // Track the selected category

  String defaultUsername = '';
  String defaultEmail = '';
  LatLng? _initialCameraPosition;
  late Position _currentPosition;
  late WebViewController _webView;

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
          .collection('users')
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
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue.withOpacity(1),
          centerTitle: true,
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.menu),
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
                leading: const Icon(Icons.account_box),
                title: const Text(
                  'Account',
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
        body: _initialCameraPosition == null
            ? Center(child: CircularProgressIndicator())
            : WebView(
                initialUrl:
                    'https://www.openstreetmap.org/#map=14/${_initialCameraPosition!.latitude}/${_initialCameraPosition!.longitude}',
                javascriptMode: JavascriptMode.unrestricted,
                onPageFinished: (String url) {
                  _requestGeolocationPermission();
                },
                onWebViewCreated: (controller) {
                  _webView = controller;
                },
              ),
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

  void _requestGeolocationPermission() async {
    final String script = '''
      navigator.geolocation.getCurrentPosition = function(success, error, options) {
        window.postMessage({ type: 'geolocation', payload: options });
      };
    ''';

    await Future.delayed(Duration(milliseconds: 500));
    await _webView.evaluateJavascript(script);
  }
}

class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);
}
