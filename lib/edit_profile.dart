import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:GuardianLink/login_screen.dart';
import 'theme.dart'; // Import the theme file

class EditProfilePage extends StatefulWidget {
  final Function(String) updateUsername;
  final bool isDarkMode;

  const EditProfilePage(
      {super.key, required this.updateUsername, required this.isDarkMode});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  bool _obscureTextCurrent = true;
  bool _obscureTextNew = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  void fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot<Map<String, dynamic>> userData = await FirebaseFirestore
          .instance
          .collection('Caregivers')
          .doc(user.uid)
          .get();

      if (userData.exists) {
        setState(() {
          _nameController.text = userData['name'];
          _emailController.text = user.email ?? '';
          _contactNumberController.text =
              userData['contactNumber'] ?? ''; // Load contact number
        });
      }
    }
  }

  void _updateProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('Caregivers')
            .doc(user.uid)
            .update({
          'name': _nameController.text,
          'contactNumber': _contactNumberController.text,
        });

        widget.updateUsername(_nameController.text);

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Profile Updated'),
              content: const Text('Your profile has been updated successfully.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } catch (e) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Failed to Update Profile'),
              content:
                  Text('An error occurred while updating your profile: $e'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  void _updatePassword() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        AuthCredential credential = EmailAuthProvider.credential(
            email: user.email!, password: _passwordController.text);
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(_newPasswordController.text);

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Password Updated'),
              content: const Text('Your password has been updated successfully.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } catch (e) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Failed to Update Password'),
              content:
                  Text('An error occurred while updating your password: $e'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: widget.isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _contactNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                  ),
                  enabled: false, // Make email field uneditable
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureTextCurrent
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureTextCurrent = !_obscureTextCurrent;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscureTextCurrent,
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _newPasswordController,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureTextNew
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureTextNew = !_obscureTextNew;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscureTextNew,
                ),
                const SizedBox(height: 16.0),
                SizedBox(
                  width: 200, // Adjusted width
                  child: ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 10),
                      backgroundColor:
                          widget.isDarkMode ? Colors.grey : Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ), // Change color to grey in dark mode
                    ),
                    child: const Text(
                      'Update Profile',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                SizedBox(
                  width: 200, // Adjusted width
                  child: ElevatedButton(
                    onPressed: _updatePassword,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 10),
                      backgroundColor:
                          widget.isDarkMode ? Colors.grey : Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ), // Change color to grey in dark mode
                    ),
                    child: const Text(
                      'Update Password',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                OutlinedButton(
                  onPressed: _deleteAccount,
                  style: ElevatedButton.styleFrom(
                      // Change button color to red
                      ),
                  child: const Text(
                    'Delete Account',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteAccount() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Prompt user to re-enter their password for security verification
        String? password = await _showPasswordDialog();
        if (password != null) {
          AuthCredential credential = EmailAuthProvider.credential(
            email: user.email!,
            password: password,
          );

          // Reauthenticate user before deleting the account
          await user.reauthenticateWithCredential(credential);

          // Delete user data from Firestore
          await FirebaseFirestore.instance
              .collection('Caregivers')
              .doc(user.uid)
              .delete();

          // Delete user account
          await user.delete();

          // Navigate to login screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to delete account: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<String?> _showPasswordDialog() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reauthentication'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Please enter your password to confirm account deletion:'),
              TextField(
                obscureText: true,
                onChanged: (value) {
                  setState(() {
                    _passwordController.text = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_passwordController.text);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}
