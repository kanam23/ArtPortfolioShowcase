// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:p2/userprofile_screen.dart';
import 'create_post.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String loggedInUsername = '';
  late String _loggedInProfilePicURL = ''; // Change to a variable

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  // Fetch username and profile picture URL
  void fetchUserData() async {
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
          _loggedInProfilePicURL =
              userData['profilePic'] ?? ''; // Update the variable
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  void navigateToUserProfileScreen(BuildContext context) async {
    final updatedProfilePicURL = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(),
      ),
    );

    // Update profile picture URL in the home screen if it's updated in the user profile screen
    if (updatedProfilePicURL != null && updatedProfilePicURL.isNotEmpty) {
      setState(() {
        _loggedInProfilePicURL = updatedProfilePicURL;
      });
    }
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
            padding: const EdgeInsets.only(left: 16.0),
            child: GestureDetector(
              onTap: () {
                navigateToUserProfileScreen(context);
              },
              child: CircleAvatar(
                backgroundImage: _loggedInProfilePicURL.isNotEmpty
                    ? NetworkImage(_loggedInProfilePicURL)
                    : const NetworkImage(
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
          final List<QueryDocumentSnapshot<Map<String, dynamic>>> documents =
              snapshot.data!.docs
                  as List<QueryDocumentSnapshot<Map<String, dynamic>>>;
          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final DocumentReference<Map<String, dynamic>> postRef =
                  documents[index].reference;
              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: postRef.get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  final Map<String, dynamic>? postData = snapshot.data!.data();
                  final int likes = postData?['likes'] ?? 0;
                  final bool likedByCurrentUser = postData?['likedBy']
                          ?.contains(FirebaseAuth.instance.currentUser!.uid) ??
                      false;
                  return PostItem(
                    postRef: postRef,
                    imageURL: postData?['imageURL'],
                    userID: postData?['userID'],
                    description: postData?['description'],
                    title: postData?['title'],
                    username: postData?['username'],
                    likes: likes,
                    likedByCurrentUser: likedByCurrentUser,
                  );
                },
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

class PostItem extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>> postRef;
  final String? imageURL;
  final String? userID;
  final String? description;
  final String? title;
  final String? username;
  final int likes;
  final bool likedByCurrentUser;

  const PostItem({
    required this.postRef,
    this.imageURL,
    this.userID,
    this.description,
    this.title,
    this.username,
    required this.likes,
    required this.likedByCurrentUser,
  });

  @override
  _PostItemState createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  late int _likes;
  late bool _likedByCurrentUser;

  @override
  void initState() {
    super.initState();
    _likes = widget.likes;
    _likedByCurrentUser = widget.likedByCurrentUser;
  }

  void _toggleLike() {
    final currentUserUid = FirebaseAuth.instance.currentUser!.uid;
    setState(() {
      if (_likedByCurrentUser) {
        _likes--;
        widget.postRef.update({
          'likes': _likes,
          'likedBy': FieldValue.arrayRemove([currentUserUid]),
        });
      } else {
        _likes++;
        widget.postRef.update({
          'likes': _likes,
          'likedBy': FieldValue.arrayUnion([currentUserUid]),
        });
      }
      _likedByCurrentUser = !_likedByCurrentUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                widget.title!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          if (widget.username != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'By ${widget.username}',
                style: const TextStyle(fontSize: 12.0, color: Colors.grey),
              ),
            ),
          if (widget.imageURL != null && widget.imageURL!.isNotEmpty)
            Center(
              child: Image.network(
                widget.imageURL!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                IconButton(
                  icon: _likedByCurrentUser
                      ? const Icon(Icons.favorite)
                      : const Icon(Icons.favorite_border),
                  color: _likedByCurrentUser ? Colors.red : null,
                  onPressed: _toggleLike,
                ),
                Text('$_likes Likes'),
              ],
            ),
          ),
          if (widget.description != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(widget.description!),
            ),
        ],
      ),
    );
  }
}
