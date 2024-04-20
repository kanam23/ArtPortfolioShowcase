// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:p2/userprofile_screen.dart';
import 'create_post.dart'; // Import the CreatePostScreen
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String loggedInUsername = '';

  @override
  void initState() {
    super.initState();
    fetchUsername();
  }

  // Method to fetch username from Firestore based on current user ID
  void fetchUsername() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot<Map<String, dynamic>> userData =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        setState(() {
          loggedInUsername = userData['username'];
        });
      }
    } catch (e) {
      print('Error fetching username: $e');
    }
  }

  void navigateToUserProfileScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(loggedInUsername.isNotEmpty
            ? "$loggedInUsername's Home Page"
            : 'Home'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(
                left: 16.0), // Adjust left padding as needed
            child: GestureDetector(
              onTap: () {
                navigateToUserProfileScreen(context);
              },
              child: CircleAvatar(
                backgroundImage: NetworkImage(
                    'https://via.placeholder.com/150'), // Placeholder image URL
                radius: 22,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('posts').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          final List<DocumentSnapshot> documents = snapshot.data!.docs;
          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final Map<String, dynamic> data =
                  documents[index].data() as Map<String, dynamic>;
              return PostItem(
                imageURL: data['imageURL'],
                userID: data['userID'],
                description: data['description'],
                title: data['title'],
                username: data['username'],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CreatePostScreen(username: loggedInUsername),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class PostItem extends StatelessWidget {
  final String? imageURL;
  final String? userID;
  final String? description;
  final String? title;
  final String? username;

  const PostItem({
    this.imageURL,
    this.userID,
    this.description,
    this.title,
    this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          if (username != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'By $username',
                style: const TextStyle(fontSize: 12.0, color: Colors.grey),
              ),
            ),
          if (imageURL != null && imageURL!.isNotEmpty)
            Center(
              child: Image.network(
                imageURL!,
                fit: BoxFit.cover, // Ensure the image fills the container
                width: double.infinity, // Ensure the image takes full width
                height: 200, // Set the fixed height for all images
              ),
            ),
          if (description != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(description!),
            ),
        ],
      ),
    );
  }
}
