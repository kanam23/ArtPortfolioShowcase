// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'login_screen.dart';
import 'create_post.dart';
import 'settings_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'request_screen.dart';
import 'dart:io';

class UserProfileScreen extends StatefulWidget {
  final String username;
  final VoidCallback refreshCallback;

  const UserProfileScreen({
    super.key,
    required this.username,
    required this.refreshCallback,
  });

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late String _loggedInUserId = '';
  late String _loggedInUsername = '';
  late String _profilePicURL = '';
  late String _profileDescription = '';
  late String _profileRole = '';
  late bool _isCurrentUser = false;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _getUserData();
  }

  void _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _loggedInUserId = user.uid;
      });
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = snapshot.data();
      if (userData != null) {
        setState(() {
          _loggedInUsername = userData['username'] ?? '';
        });
      }
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: widget.username)
        .get();
    final userDoc = snapshot.docs.first;
    final userData = userDoc.data();
    setState(() {
      _profilePicURL = userData['profilePic'] ?? '';
      _profileDescription = userData['description'] ?? '';
      _profileRole = userData['role'] ?? '';
      _isCurrentUser = _loggedInUsername == widget.username;
    });
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  void _navigateToCreatePostScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(username: _loggedInUsername),
      ),
    );
  }

  Future<void> _changeProfilePic() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      // Upload image to Firebase Storage
      String imageName = 'profile_pic_${DateTime.now().millisecondsSinceEpoch}';
      final ref = FirebaseStorage.instance.ref().child(imageName);
      await ref.putFile(imageFile);
      final imageUrl = await ref.getDownloadURL();

      // Update profilePicURL in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_loggedInUserId)
          .update({'profilePic': imageUrl});

      // Update UI
      setState(() {
        _profilePicURL = imageUrl;
      });
    }
  }

  Future<void> _updateProfileDescription(String newDescription) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_loggedInUserId)
          .update({'description': newDescription});
      setState(() {
        _profileDescription = newDescription;
      });
    } catch (e) {
      print('Error updating profile description: $e');
    }
  }

  Future<void> _editProfileDescription() async {
    final newDescription = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Description'),
          content: TextField(
            controller: _descriptionController,
            decoration:
                const InputDecoration(hintText: 'Enter new description'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, _descriptionController.text);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newDescription != null && newDescription.isNotEmpty) {
      _updateProfileDescription(newDescription);
    }
  }

  void _sendMessageRequest(String message) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final sender =
            _loggedInUsername; // Use the currently logged-in user as the sender
        final receiver =
            widget.username; // Use the profile being viewed as the receiver
        final timestamp = Timestamp.now();

        // Store the request in the Firestore "requests" collection
        await FirebaseFirestore.instance.collection('requests').add({
          'sender': sender,
          'receiver': receiver,
          'message': message,
          'timestamp': timestamp,
        });

        // Show a success message or navigate to another screen
        Navigator.pop(context); // Close the dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request sent successfully'),
          ),
        );
      } catch (e) {
        print('Error sending request: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send request'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.username}\'s Profile',
        ),
        actions: [
          if (_isCurrentUser)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.mail),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RequestScreen()),
                    );
                  },
                ),
              ],
            ),
          if (!_isCurrentUser)
            IconButton(
              icon: const Icon(Icons.message),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Send Message to ${widget.username}'),
                    content: TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        hintText: 'Enter your message',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            _sendMessageRequest(_descriptionController.text),
                        child: const Text('Submit a Request'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _isCurrentUser ? _changeProfilePic : null,
                      child: CircleAvatar(
                        radius: 80,
                        backgroundImage: _profilePicURL.isNotEmpty
                            ? NetworkImage(_profilePicURL)
                            : null,
                        child: _profilePicURL.isEmpty
                            ? const Icon(Icons.person,
                                size: 80, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.username,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Role: $_profileRole',
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Description: $_profileDescription',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ),
                                if (_isCurrentUser)
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: _editProfileDescription,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection('posts')
                          .where('username', isEqualTo: widget.username)
                          .snapshots(),
                      builder:
                          (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('No posts yet.'));
                        }
                        return GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8.0,
                          crossAxisSpacing: 8.0,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: snapshot.data!.docs
                              .map((DocumentSnapshot document) {
                            Map<String, dynamic> data =
                                document.data() as Map<String, dynamic>;
                            return Image.network(
                              data['imageURL'],
                              fit: BoxFit.cover,
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isCurrentUser) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _navigateToCreatePostScreen,
                child: const Text(
                  'Create Post',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
