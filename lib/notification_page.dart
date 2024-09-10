import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Import the intl package

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _username = ''; // Replace with actual username
  List<Map<String, dynamic>> _notifications = []; // Updated to handle message and timestamp separately

  @override
  void initState() {
    super.initState();
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    _loadUsername();
  }

  Future<void> _loadUsername() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await _firestore
          .collection('Caregivers')
          .doc(user.uid)
          .get();

      setState(() {
        _username = userData['name']; // Assume 'name' field contains the username
      });

      _loadNotifications(); // Load notifications after username is set
    }
  }

  Future<void> _loadNotifications() async {
    if (_username.isNotEmpty) {
      final docRef = _firestore.collection('notifications').doc(_username);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        List<String> notifications = List<String>.from(docSnapshot.data()?['messages'] ?? []);
        notifications.sort((a, b) {
          final timestampA = a.split(' - ').last;
          final timestampB = b.split(' - ').last;
          final dateA = DateTime.tryParse(timestampA);
          final dateB = DateTime.tryParse(timestampB);
          return (dateB ?? DateTime.now()).compareTo(dateA ?? DateTime.now()); // Sort in descending order
        });

        setState(() {
          _notifications = notifications.map((msg) {
            // Split message and timestamp
            final parts = msg.split(' - ');
            if (parts.length == 2) {
              final message = parts[0];
              final timestamp = parts[1];
              final formattedDate = _formatDate(timestamp);
              return {
                'message': message,
                'formattedDate': formattedDate,
              };
            } else {
              return {
                'message': msg,
                'formattedDate': 'Invalid date',
              }; // Handle cases where the message format is incorrect
            }
          }).toList();
        });
      }
    }
  }

  String _formatDate(String timestamp) {
    try {
      final date = DateTime.tryParse(timestamp);
      if (date != null) {
        final formatter = DateFormat('MM/dd/yy HH:mm');
        return formatter.format(date);
      } else {
        return 'Invalid date'; // Handle invalid date format
      }
    } catch (e) {
      return 'Error formatting date'; // Handle any other errors
    }
  }

  Future<void> _showNotification(String message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id', // Channel ID
      'your_channel_name', // Channel Name
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      'Notification', // Notification Title
      message, // Notification Body
      platformChannelSpecifics,
      payload: 'notification_payload', // Optional payload
    );
  }

  Future<void> _onDidReceiveNotificationResponse(NotificationResponse response) async {
    final String? payload = response.payload;

    if (payload != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => YourTargetPage(payload: payload),
        ),
      );
    }
  }

  Future<void> _sendNotificationToFirestore(String message) async {
    if (_username.isNotEmpty) {
      final docRef = _firestore.collection('notifications').doc(_username);

      await _firestore.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);

        if (!docSnapshot.exists) {
          final timestamp = DateTime.now().toIso8601String();
          transaction.set(docRef, {
            'messages': [
              '$message - $timestamp',
            ],
          });
        } else {
          List<String> messages = List<String>.from(docSnapshot.data()?['messages'] ?? []);
          final timestamp = DateTime.now().toIso8601String();
          messages.add('$message - $timestamp');
          transaction.update(docRef, {
            'messages': messages,
          });
        }
      });

      _showNotification(message); // Show the notification
      _loadNotifications(); // Refresh the list
    }
  }

  void _showMessageDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Notification Details'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                final message = notification['message'] as String;
                final formattedDate = notification['formattedDate'] as String;

                return ListTile(
                  title: Text(
                    message,
                    overflow: TextOverflow.ellipsis, // Truncate long text
                    maxLines: 1, // Show only one line
                  ),
                  subtitle: Text(
                    formattedDate,
                    style: TextStyle(color: Colors.grey[600]), // Style the date differently
                  ),
                  onTap: () => _showMessageDialog('$message - $formattedDate'),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _sendNotificationToFirestore('This is a new notificationnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn');
            },
            child: const Text('Send Notification'),
          ),
        ],
      ),
    );
  }
}

class YourTargetPage extends StatelessWidget {
  final String payload;

  const YourTargetPage({Key? key, required this.payload}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Target Page'),
      ),
      body: Center(
        child: Text('Payload received: $payload'),
      ),
    );
  }
}
