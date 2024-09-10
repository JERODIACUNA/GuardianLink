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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart'; // Import Firebase Realtime Database
import 'package:GuardianLink/edit_device_location.dart'; 
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final DatabaseReference _deviceLocationRef = FirebaseDatabase.instance.ref('device_location');

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
  bool isGeofencingEnabled = false;
  LatLng _previousLocation = LatLng(0, 0);
  double _previousRadius = 5.0;
  Map<String, Marker> _markers = {};

  Future<void> _setLoggedIn(bool isLoggedIn) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', isLoggedIn);
  }
void _updateMapWithLocation(String? location) {
    if (location != null) {
      final regex = RegExp(r'Latitude (-?\d+\.\d+), Longitude (-?\d+\.\d+)');
      final match = regex.firstMatch(location);
      if (match != null) {
        final latitude = double.parse(match.group(1)!);
        final longitude = double.parse(match.group(2)!);
        final latLng = LatLng(latitude, longitude);

        setState(() {
          _mapController.animateCamera(CameraUpdate.newLatLng(latLng));
          _markers['new_device'] = Marker(
            markerId: MarkerId('new_device'),
            position: latLng,
            infoWindow: InfoWindow(title: 'New Device Location'),
          );
        });
      }
    }
  }
  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchUsername();
    _checkLocationPermission();
    _loadTheme();
    GeofencingService.startGeofencing(); // Call geofencing start method
    fetchGeofencingData(); // Call function to fetch geofencing data
    _fetchDeviceLocations(); // Fetch device locations and update map
    _fetchUserDevices(); // Fetch devices associated with the user
  }
  Future<void> associateDeviceWithUser(String deviceId, String userId) async {
    final DatabaseReference userDevicesRef = FirebaseDatabase.instance.ref('user_devices/$userId');
    await userDevicesRef.child(deviceId).set(true);
  }

  Future<List<String>> fetchUserDevices(String userId) async {
    final DatabaseReference userDevicesRef = FirebaseDatabase.instance.ref('user_devices/$userId');
    DataSnapshot snapshot = await userDevicesRef.get();
    if (snapshot.exists) {
      Map<dynamic, dynamic> devices = snapshot.value as Map<dynamic, dynamic>;
      return devices.keys.map((key) => key.toString()).toList();
    } else {
      return [];
    }
  }

 Future<void> _fetchUserDevices() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    String userId = user.uid;
    List<String> userDevices = await fetchUserDevices(userId);

    for (String deviceId in userDevices) {
      try {
        final snapshot = await _deviceLocationRef.child(deviceId).get();
        if (snapshot.exists) {
          final dynamic value = snapshot.value;
          if (value is Map) {
            final Map<dynamic, dynamic> location = value.cast<dynamic, dynamic>();
            final latitude = (location['latitude'] as num).toDouble();
            final longitude = (location['longitude'] as num).toDouble();
            setState(() {
              _markers[deviceId] = Marker(
                markerId: MarkerId(deviceId),
                position: LatLng(latitude, longitude),
                infoWindow: InfoWindow(title: deviceId),
              );
            });
          } else {
            print('Unexpected data format for device $deviceId');
          }
        } else {
          print('No data found for device $deviceId');
        }
      } catch (error) {
        print('Error fetching location for device $deviceId: $error');
      }
    }
  } else {
    print('No user is currently authenticated.');
  }
}



Future<void> _fetchDeviceLocations() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    String userId = user.uid;
    
    try {
      // Fetch the paired devices for the current user
      final pairedDevicesRef = FirebaseDatabase.instance.ref('device_pairings');
      final pairedDevicesSnapshot = await pairedDevicesRef.child(userId).get();
      
      if (pairedDevicesSnapshot.exists) {
        final userPairedDevices = pairedDevicesSnapshot.value as Map<dynamic, dynamic>;

        // Fetch and display the location of each paired device
        for (String deviceId in userPairedDevices.keys) {
          final deviceLocationRef = FirebaseDatabase.instance.ref('device_location').child(deviceId);
          final locationSnapshot = await deviceLocationRef.get();

          if (locationSnapshot.exists) {
            final locationData = locationSnapshot.value as Map<dynamic, dynamic>;
            final latitude = (locationData['latitude'] as num).toDouble();
            final longitude = (locationData['longitude'] as num).toDouble();
            
            setState(() {
              _markers[deviceId] = Marker(
                markerId: MarkerId(deviceId),
                position: LatLng(latitude, longitude),
                infoWindow: InfoWindow(title: deviceId),
              );
            });
          } else {
            print('Location data not found for device $deviceId');
          }
        }
      } else {
        print('No paired devices found.');
      }
    } catch (e) {
      print('Error fetching device locations: $e');
    }
  } else {
    print('No user is currently authenticated.');
  }
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
      await _setLoggedIn(false); // Clear login status
      Navigator.popUntil(context,
          (route) => route.isFirst); // Remove all routes until the root route
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => LoginScreen(onLogin: (bool) {})));
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
        key: _scaffoldKey, // Set the global key for the scaffold
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
                leading: const Icon(Icons.edit_location),
                title: Text(
                  'Edit Device Location',
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
                      builder: (context) => EditDeviceLocationPage(),
                    ),
                  );
                  _scaffoldKey.currentState?.closeDrawer(); // Close the drawer
                },
              ),
              ListTile(
                leading: const Icon(Icons.save),
                title: Text(
                  'Edit Geofence',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  setState(() {
                    isGeofencingEnabled = !isGeofencingEnabled;
                  });
                  _scaffoldKey.currentState?.closeDrawer(); // Close the drawer
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: Text(
                  'Pair a Device',
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
                      builder: (context) =>  SearchForDevicePage(
                      onLocationUpdated:(location){_updateMapWithLocation(location);
                      },
                      ),
                    ),
                  );
                   _scaffoldKey.currentState?.closeDrawer();
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
                onTap: isGeofencingEnabled ? _selectLocation : null,
                markers: _markers.values.toSet(),
                circles: circles,
              ),
            ),
            if (isGeofencingEnabled) ...[
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
                        fillColor: Colors.blue.withOpacity(0.1),
                        strokeColor: Colors.blue,
                      ),
                    ]);
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      String? username =
                          await GeofencingService.fetchUsername();
                      if (username != null) {
                        await GeofencingService.storeGeofencingData(
                          fenceRadius: fenceRadius,
                          selectedLocation: _selectedLocation,
                          username: username,
                        );
                        setState(() {
                          isGeofencingEnabled = false;
                        });
                      } else {
                        print('Username not found or an error occurred.');
                      }
                    },
                    child: Text('Save'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isGeofencingEnabled = false; // Cancel editing
                        _selectedLocation = _previousLocation; // Restore previous location
                        _sliderValue = _previousRadius; // Restore previous slider value
                        fenceRadius = _previousRadius; // Restore previous fence radius
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
                    },
                    style: ElevatedButton.styleFrom(
                      primary: const Color.fromARGB(255, 255, 130, 121), // Red color for cancel button
                    ),
                    child: Text('Cancel'),
                  )
                ],
              ),
            ],
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
    if (isGeofencingEnabled) {
      setState(() {
        _selectedLocation = position;
        _sliderValue = 5; // Reset slider value to 5
        fenceRadius = _sliderValue; // Ensure fence radius is also reset
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
    }
  }

  void fetchGeofencingData() async {
    GeofencingService.fetchGeofencingData(
      onDataReceived: (fenceRadius, location) {
        setState(() {
          // Store the previous geofence data
          _previousLocation = location;
          _previousRadius = fenceRadius;
          
          // Update the current geofence data
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
          _mapController.animateCamera(
            CameraUpdate.newLatLng(_selectedLocation),
          );
        });
      },
    );
  }
}
