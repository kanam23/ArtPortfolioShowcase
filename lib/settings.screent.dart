import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'create_post.dart'; // Import the CreatePostScreen

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = snapshot.data();
      if (userData != null) {
        setState(() {
          _loggedInUsername = userData['username'] ?? '';
          _profilePicURL = userData['profilePic'] ?? '';
        });
      }
    }
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

  void _changeProfilePic() async {
    // Add logic to change profile picture here
    // For example, you can use image picker to select a new profile picture
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: Colors.amber,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _loggedInUsername,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            GestureDetector(
              onTap: _changeProfilePic,
              child: CircleAvatar(
                radius: 80,
                backgroundImage: _profilePicURL.isNotEmpty
                    ? NetworkImage(_profilePicURL)
                    : null,
                child: _profilePicURL.isEmpty
                    ? Icon(Icons.person, size: 80, color: Colors.white)
                    : null,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .where('userID',
                        isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No posts yet.'));
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var post = snapshot.data!.docs[index];
                      return ListTile(
                        title: Text(post['userID']), // Example field
                        leading:
                            Image.network(post['imageURL']), // Display image
                        subtitle: Text(post['description']), // Example field
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _navigateToCreatePostScreen,
              child: const Text(
                'Create Post',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.grey[900],
    );
  }
}
