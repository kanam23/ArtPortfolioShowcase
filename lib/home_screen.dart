// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_post.dart'; // Import the CreatePostScreen

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(loggedInUsername.isNotEmpty
            ? "$loggedInUsername's Home Page"
            : 'Home'),
      ),
      body: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          return PostItem(post: posts[index]);
        },
      ),
      // Inside HomeScreen's floatingActionButton onPressed method

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
  final Post post;

  const PostItem({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  post.username,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (post.imageURL.isNotEmpty)
            Image.network(
              post.imageURL,
              fit: BoxFit.cover,
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(post.description),
          ),
        ],
      ),
    );
  }
}

// Define a Post class to represent a single post
class Post {
  final String imageURL;
  final String userID;
  final String username;
  final String title; // Add the title field
  final String description;

  Post({
    required this.imageURL,
    required this.userID,
    required this.username,
    required this.title,
    required this.description,
  });

  factory Post.fromFirestore(Map<String, dynamic> data) {
    return Post(
      imageURL: data['imageURL'] ?? '',
      userID: data['userID'] ?? '',
      username: data['username'] ?? '',
      title: data['title'] ?? '', // Initialize title field
      description: data['description'] ?? '',
    );
  }
}
