import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class CreatePostScreen extends StatefulWidget {
  final String username;

  const CreatePostScreen({Key? key, required this.username});

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController imageController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  File? _image;
  bool _useImageURL = false;
  final picker = ImagePicker();

  void _getImageFromGallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _useImageURL =
            false; // Ensure image URL field is cleared when an image is selected
      });
    }
  }

  void _submitPost() async {
    if (_formKey.currentState!.validate()) {
      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          String? imageURL;

          if (_useImageURL) {
            imageURL = imageController.text;
          } else if (_image != null) {
            final ref = firebase_storage.FirebaseStorage.instance
                .ref()
                .child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');
            await ref.putFile(_image!);
            imageURL = await ref.getDownloadURL();
          }

          String userID = user.uid;

          await FirebaseFirestore.instance.collection('posts').add({
            'title': titleController.text,
            'username': widget.username,
            'description': descriptionController.text,
            'imageURL': imageURL ?? '',
            'userID': userID,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post created successfully'),
              backgroundColor: Colors.green,
            ),
          );

          titleController.clear();
          descriptionController.clear();
          imageController.clear();
          setState(() {
            _image = null;
          });

          Navigator.pop(context);
        }
      } catch (e) {
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
                    Row(
                      children: [
                        Checkbox(
                          value: _useImageURL,
                          onChanged: (value) {
                            setState(() {
                              _useImageURL = value!;
                              _image =
                                  null; // Clear selected image if user switches to image URL
                            });
                          },
                        ),
                        const Text('Use Image URL'),
                      ],
                    ),
                    if (!_useImageURL) ...[
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
                        onPressed: _getImageFromGallery,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add),
                            const SizedBox(width: 8),
                            Text(
                              _image == null ? 'Select Image' : 'Change Image',
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_useImageURL) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: imageController,
                        decoration: const InputDecoration(
                          labelText: 'Image URL',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: null,
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
