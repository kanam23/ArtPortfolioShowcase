// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:p2/userprofile_screen.dart';
import 'create_post.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String loggedInUsername = '';
  late String loggedInUserProfilePicURL = '';

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

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
          loggedInUserProfilePicURL = userData['profilePic'] ?? '';
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  void navigateToUserProfileScreen(
      BuildContext context, String username) async {
    final updatedProfilePicURL = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          username: username,
          refreshCallback: () {
            fetchUserData();
          },
        ),
      ),
    );

    if (updatedProfilePicURL != null && updatedProfilePicURL.isNotEmpty) {
      setState(() {
        loggedInUserProfilePicURL = updatedProfilePicURL;
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
                navigateToUserProfileScreen(context, loggedInUsername);
              },
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircleAvatar(
                      radius: 22,
                      backgroundImage:
                          NetworkImage('https://via.placeholder.com/150'),
                    );
                  }
                  if (snapshot.hasError) {
                    return const CircleAvatar(
                      radius: 22,
                      backgroundImage:
                          NetworkImage('https://via.placeholder.com/150'),
                    );
                  }
                  final userData = snapshot.data!.data();
                  final profilePicURL =
                      (userData as Map<String, dynamic>)['profilePic'] ?? '';
                  return CircleAvatar(
                    radius: 22,
                    backgroundImage: profilePicURL.isNotEmpty
                        ? NetworkImage(profilePicURL)
                        : const NetworkImage('https://via.placeholder.com/150'),
                  );
                },
              ),
            ),
          ),
        ],
        automaticallyImplyLeading: false, // Hide the back arrow
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
              final postData = documents[index].data();
              final int likes = postData['likes'] ?? 0;
              final bool likedByCurrentUser = postData['likedBy']
                      ?.contains(FirebaseAuth.instance.currentUser!.uid) ??
                  false;
              final String? username = postData['username'];
              final List<dynamic> commentsData = postData['comments'] ?? [];
              final List<Map<String, dynamic>> comments =
                  List<Map<String, dynamic>>.from(commentsData);
              return PostItem(
                postRef: postRef,
                imageURL: postData['imageURL'],
                userID: postData['userID'],
                description: postData['description'],
                title: postData['title'],
                username: username,
                likes: likes,
                likedByCurrentUser: likedByCurrentUser,
                comments: comments,
                loggedInUsername: loggedInUsername,
                onTapProfile: () {
                  navigateToUserProfileScreen(context, username!);
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
  final List<Map<String, dynamic>> comments;
  final String loggedInUsername;
  final VoidCallback onTapProfile;

  const PostItem({
    required this.postRef,
    this.imageURL,
    this.userID,
    this.description,
    this.title,
    this.username,
    required this.likes,
    required this.likedByCurrentUser,
    required this.comments,
    required this.loggedInUsername,
    required this.onTapProfile,
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

  void _showCommentsDialog(
      BuildContext context, DocumentReference<Map<String, dynamic>> postRef) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Comments'),
          content: CommentsDialog(
            postRef: postRef,
            loggedInUsername: widget.loggedInUsername,
          ),
          actions: <Widget>[
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
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.username != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'By ${widget.username}',
                    style: const TextStyle(fontSize: 12.0, color: Colors.grey),
                  ),
                ),
              GestureDetector(
                onTap: widget.onTapProfile,
                child: const Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 4),
                    Text('See User Profile'),
                    SizedBox(width: 8), // Add spacing here
                  ],
                ),
              ),
            ],
          ),
          if (widget.title != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                widget.title!,
                style: const TextStyle(fontWeight: FontWeight.bold),
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
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.comment),
                  onPressed: () {
                    _showCommentsDialog(context, widget.postRef);
                  },
                ),
                Text('${widget.comments.length} Comments'),
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

class CommentsDialog extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>> postRef;
  final String loggedInUsername;

  const CommentsDialog({
    super.key,
    required this.postRef,
    required this.loggedInUsername,
  });

  @override
  _CommentsDialogState createState() => _CommentsDialogState();
}

class _CommentsDialogState extends State<CommentsDialog> {
  late TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _postComment() async {
    final String commentText = _commentController.text.trim();
    if (commentText.isNotEmpty) {
      try {
        final newComment = {
          'text': commentText,
          'username': widget.loggedInUsername,
        };
        await widget.postRef.update({
          'comments': FieldValue.arrayUnion([newComment]),
        });
        _commentController.clear();
      } catch (error) {
        print('Error posting comment: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<DocumentSnapshot>(
              stream: widget.postRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                Map<String, dynamic>? data =
                    snapshot.data?.data() as Map<String, dynamic>?;
                if (data == null || !data.containsKey('comments')) {
                  return const Text('No comments');
                }

                List<dynamic> commentsData = data['comments'];
                if (commentsData.isEmpty) {
                  return const Text('No comments');
                }

                List<Map<String, dynamic>> comments =
                    List<Map<String, dynamic>>.from(commentsData);

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(comments[index]['text']),
                      subtitle: Text('By ${comments[index]['username']}'),
                    );
                  },
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'Add a comment...',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _postComment,
                child: const Text('Post'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
