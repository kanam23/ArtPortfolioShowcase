import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class RequestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Handle the case where the user is not logged in
      return const Scaffold(
        body: Center(
          child: Text('User not logged in'),
        ),
      );
    } else {
      String currentUserUsername = ''; // Initialize with an empty string

      // Get the current user's username from Firestore
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get()
          .then((DocumentSnapshot userDoc) {
        currentUserUsername = userDoc.get('username');
      });

      return Scaffold(
        appBar: AppBar(
          title: const Text('Message Requests'),
        ),
        body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('requests')
              .where('receiver', isEqualTo: currentUserUsername)
              .snapshots(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text('No message requests'),
              );
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (BuildContext context, int index) {
                  var request = snapshot.data!.docs[index];
                  var sender = request['sender'];
                  var message = request['message'];
                  var timestamp = request['timestamp'];
                  var formattedDate =
                      DateFormat('MMM dd, yyyy').format(timestamp.toDate());
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('From: $sender'),
                          Text(
                            'Message: $message',
                            style: const TextStyle(fontSize: 16.0),
                          ),
                          Text('Timestamp: $formattedDate'),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Checkbox(
                                value: false,
                                onChanged: (_) {
                                  // Handle checkbox state change
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  // Add code here to delete the request
                                  request.reference.delete();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      );
    }
  }
}
