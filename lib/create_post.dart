import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class CreatePostScreen extends StatefulWidget {
  final String username;

  const CreatePostScreen({Key? key, required this.username}) : super(key: key);

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController imageController =
      TextEditingController(); // Add this controller
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  File? _image;

  void _getImage() {
    setState(() {
      _image = null; // Reset image when URL is provided
    });
  }

  void _submitPost() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Get current user
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          String? imageURL;

          // Check if URL is provided
          if (imageController.text.isNotEmpty) {
            imageURL = imageController.text; // Use provided URL
          } else if (_image != null) {
            // Upload image to Firebase Storage
            final ref = firebase_storage.FirebaseStorage.instance
                .ref()
                .child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');
            await ref.putFile(_image!);
            imageURL = await ref.getDownloadURL();
          }

          // Add post to Firestore
          await FirebaseFirestore.instance.collection('posts').add({
            'title': titleController.text,
            'username': widget.username,
            'description': descriptionController.text,
            'imageURL': imageURL ?? '',
            // Add other fields as needed
          });

          // Show success notification
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post created successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Clear input fields
          titleController.clear();
          descriptionController.clear();
          imageController.clear();
          setState(() {
            _image = null;
          });

          // Navigate back to home screen
          Navigator.pop(context);
        }
      } catch (e) {
        // Show error notification
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create post'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Post'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Create Post',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Title is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller:
                          imageController, // Use imageController for URL input
                      decoration: const InputDecoration(
                        labelText: 'Image URL', // Change label to Image URL
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        // You can add validation for URL format if needed
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _image == null
                        ? const Column(
                            children: [
                              Text(
                                'Add an image',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 16),
                            ],
                          )
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.file(
                                _image!,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: const Icon(Icons.cancel),
                                  onPressed: () {
                                    setState(() {
                                      _image = null;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                    ElevatedButton(
                      onPressed: _getImage,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add),
                          const SizedBox(width: 8),
                          Text(
                              _image == null ? 'Select Image' : 'Change Image'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: null, // Allow multiple lines for description
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Description is required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _submitPost,
        icon: const Icon(Icons.add),
        label: const Text('Create'),
      ),
    );
  }
}
