// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_post.dart'; // Import the CreatePostScreen
import 'package:firebase_auth/firebase_auth.dart';

import 'settings.screent.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Define a list to store the fetched posts
  List<Post> posts = [];
  String loggedInUsername = '';

  // Method to fetch posts from Firestore
  Future<void> fetchPosts() async {
    try {
      // Fetch posts from Firestore collection
      QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance.collection('posts').get();

      // Parse fetched documents into Post objects
      List<Post> fetchedPosts = snapshot.docs.map((doc) {
        return Post.fromFirestore(doc.data());
      }).toList();

      // Update the state with fetched posts
      setState(() {
        posts = fetchedPosts;
      });
    } catch (e) {
      print('Error fetching posts: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    // Fetch posts when the screen loads
    fetchPosts();
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

  void navigateToSettingsScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            loggedInUsername.isNotEmpty ? "$loggedInUsername's Home" : 'Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              navigateToSettingsScreen(context);
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          // Display each post in a ListTile
          return ListTile(
            title: Text(posts[index].userID), // Example field
            leading: Image.network(posts[index].imageURL), // Display image
            // Display other relevant information about the post
            subtitle: Text(posts[index].description), // Example field
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

// Define a Post class to represent a single post
class Post {
  final String imageURL;
  final String userID;
  final String description; // Example field, add more as needed

  Post({
    required this.imageURL,
    required this.userID,
    required this.description,
  });

  // Factory method to create a Post object from Firestore document data
  factory Post.fromFirestore(Map<String, dynamic> data) {
    return Post(
      imageURL: data['imageURL'],
      userID: data['userID'],
      description: data['description'],
    );
  }
}
