import 'package:GuardianLink/edit_profile.dart';
import 'package:GuardianLink/login_screen.dart';
import 'package:GuardianLink/notification_page.dart';
import 'package:GuardianLink/search_for_device.dart';
import 'package:geolocator/geolocator.dart';
import 'theme.dart'; // Import the theme file
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'geofencing.dart'; // Import the geofencing file

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late double fenceRadius = 5.0;
  late Set<Circle> circles = {};
  late double _sliderValue = 5.0;
  late LatLng _selectedLocation = LatLng(0, 0);
  String selectedCategory = '';
  String defaultUsername = '';
  String defaultEmail = '';
  late LatLng _initialCameraPosition = LatLng(0, 0);
  late Position _currentPosition;
  late GoogleMapController _mapController;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchUsername();
    _checkLocationPermission();
    _loadTheme();
    GeofencingService.startGeofencing(); // Call geofencing start method
    fetchGeofencingData(); // Call function to fetch geofencing data
  }

  void fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        defaultEmail = user.email ?? '';
      });
    }
  }

  void fetchUsername() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot<Map<String, dynamic>> userData = await FirebaseFirestore
          .instance
          .collection('Caregivers')
          .doc(user.uid)
          .get();

      if (userData.exists) {
        setState(() {
          defaultUsername = userData['name'];
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
        (route) => false,
      );
    } catch (e) {
      print(e);
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
      theme: AppTheme.getTheme(isDarkMode),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: isDarkMode
              ? Color.fromARGB(255, 5, 5, 22)
              : Colors.blue.withOpacity(1),
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
                _navigateToNotifications(context);
              },
            ),
            IconButton(
              icon: const CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage('lib/assets/logo.png'),
              ),
              onPressed: () {},
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
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                accountEmail: Text(
                  defaultEmail,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                decoration: BoxDecoration(
                  color:
                      isDarkMode ? Color.fromARGB(255, 5, 5, 22) : Colors.blue,
                ),
                currentAccountPicture: const CircleAvatar(
                  backgroundImage: AssetImage('lib/assets/logo.png'),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: Text(
                  'Dark Mode',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Switch(
                  value: isDarkMode,
                  onChanged: (value) {
                    setState(() {
                      isDarkMode = value;
                      AppTheme.setThemePreference(isDarkMode);
                    });
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.search_sharp),
                title: Text(
                  'Search for Device',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white : Colors.black,
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
                title: Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white : Colors.black,
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
                        isDarkMode: isDarkMode,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: Text(
                  'About Us',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(
                  'Log Out',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white : Colors.black,
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
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Expanded(
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _initialCameraPosition,
                          zoom: 16,
                        ),
                        onMapCreated: (GoogleMapController controller) {
                          _mapController = controller;
                        },
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        onTap: _selectLocation,
                        markers: {
                          Marker(
                            markerId: MarkerId('selectedLocation'),
                            position: _selectedLocation,
                            infoWindow: InfoWindow(
                              title: 'Selected Location',
                            ),
                          ),
                        },
                        circles: circles,
                      ),
                    ),
                    Slider(
                      value: _sliderValue,
                      min: 5.0,
                      max: 50.0,
                      divisions: 9,
                      label: 'Geofence Radius: $_sliderValue meters',
                      onChanged: (value) {
                        setState(() {
                          _sliderValue = value;
                          fenceRadius = value;
                          circles = Set.from([
                            Circle(
                                circleId: CircleId('geofence'),
                                center: _selectedLocation,
                                radius: fenceRadius,
                                strokeWidth: 2,
                                fillColor: Colors.green.withOpacity(0.1),
                                strokeColor: Color.fromARGB(255, 7, 252, 43)),
                          ]);
                        });
                      },
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        String? username = await GeofencingService
                            .fetchUsername(); // Fetch username
                        if (username != null) {
                          GeofencingService.storeGeofencingData(
                            fenceRadius: fenceRadius,
                            selectedLocation: _selectedLocation,
                            username:
                                username, // Pass the nullable username here
                          );
                        } else {
                          print('Username not found or an error occurred.');
                        }
                      },
                      child: Text('Save Geofencing Data'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

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

  void _getCurrentLocation() async {
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

  void _loadTheme() async {
    bool savedTheme = await AppTheme.getThemePreference();
    setState(() {
      isDarkMode = savedTheme;
    });
  }

  void _selectLocation(LatLng position) {
    setState(() {
      _selectedLocation = position;
      circles = Set.from([
        Circle(
          circleId: CircleId('geofence'),
          center: _selectedLocation,
          radius: fenceRadius,
          strokeWidth: 2,
          fillColor: Colors.green.withOpacity(0.1),
          strokeColor: Color.fromARGB(255, 7, 252, 43),
        ),
      ]);
    });
  }

  void fetchGeofencingData() async {
    GeofencingService.fetchGeofencingData(
        onDataReceived: (fenceRadius, location) {
      setState(() {
        _selectedLocation = location;
        _sliderValue = fenceRadius;
        circles = Set.from([
          Circle(
            circleId: CircleId('geofence'),
            center: _selectedLocation,
            radius: fenceRadius,
            strokeWidth: 2,
            fillColor: Colors.blue.withOpacity(0.1),
            strokeColor: Colors.blue,
          ),
        ]);
      });
    });
  }
}
