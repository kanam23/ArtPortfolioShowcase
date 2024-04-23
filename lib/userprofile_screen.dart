import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'login_screen.dart';
import 'create_post.dart'; // Import the CreatePostScreen
import 'settings_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UserProfileScreen extends StatefulWidget {
  final String username;

  const UserProfileScreen({Key? key, required this.username});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late String _loggedInUserId = '';
  late String _loggedInUsername = '';
  late String _profilePicURL = '';

  @override
  void initState() {
    super.initState();
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

    // Retrieve profile picture URL for the user being viewed
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: widget.username)
        .get();
    final userDoc = snapshot.docs.first;
    final userData = userDoc.data();
    setState(() {
      _profilePicURL = userData['profilePic'] ?? '';
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

  @override
  Widget build(BuildContext context) {
    final bool isCurrentUserProfile = widget.username == _loggedInUsername;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.username.isNotEmpty
              ? "${widget.username}'s Profile"
              : 'Profile',
        ),
        backgroundColor: Colors.amber,
        actions: isCurrentUserProfile
            ? [
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
              ]
            : [],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            GestureDetector(
              onTap: isCurrentUserProfile ? _changeProfilePic : null,
              child: CircleAvatar(
                radius: 80,
                backgroundImage: _profilePicURL.isNotEmpty
                    ? NetworkImage(_profilePicURL)
                    : null,
                child: _profilePicURL.isEmpty
                    ? const Icon(Icons.person, size: 80, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.username,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .where('username', isEqualTo: widget.username)
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No posts yet.'));
                  }
                  return GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8.0,
                    crossAxisSpacing: 8.0,
                    children:
                        snapshot.data!.docs.map((DocumentSnapshot document) {
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
            ),
            if (isCurrentUserProfile) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _navigateToCreatePostScreen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
                child: const Text(
                  'Create Post',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
