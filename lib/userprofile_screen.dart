import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'create_post.dart'; // Import the CreatePostScreen
import 'settings_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key});

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
    String? newProfilePicURL = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Profile Picture'),
        content: TextField(
          decoration: InputDecoration(hintText: 'Enter Image URL'),
          onChanged: (value) => setState(() => _profilePicURL = value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_profilePicURL.isNotEmpty) {
                // Update profilePicURL in Firestore
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(_loggedInUserId)
                    .update({'profilePic': _profilePicURL});
                // Close the dialog and pass the updated profilePicURL back to the calling screen
                Navigator.pop(context, _profilePicURL);
              } else {
                // If no URL provided, show an error or handle it accordingly
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );

    // Update profilePicURL directly in the state with the updated value
    if (newProfilePicURL != null && newProfilePicURL.isNotEmpty) {
      setState(() {
        _profilePicURL = newProfilePicURL;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile Screen'),
        backgroundColor: Colors.amber,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Navigate to the settings screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _changeProfilePic,
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
              _loggedInUsername,
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
                    .where('userID', isEqualTo: _loggedInUserId)
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
        ),
      ),
    );
  }
}
