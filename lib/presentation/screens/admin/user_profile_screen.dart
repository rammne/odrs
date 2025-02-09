import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AUserProfileScreen extends StatelessWidget {
  final String userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AUserProfileScreen({required this.userId});

  String formatTimestamp(Timestamp timestamp) {
    return DateFormat('MMMM d, yyyy \'at\' h:mm:ss a')
        .format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(title: Text('User Profile')),
      body: FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('users').doc(userId).get(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return Center(child: Text('User not found.'));
          }

          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
          String studentNumber =
              userData['student_number'] ?? 'No student number';

          return Column(
            children: [
              ListTile(
                leading: Icon(Icons.person, size: 50),
                title: Text(userData['name'] ?? 'No name'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userData['email'] ?? 'No email'),
                    Text('Student Number: $studentNumber'),
                  ],
                ),
              ),
              Divider(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('document_requests')
                      .where('studentNumber', isEqualTo: studentNumber)
                      .snapshots(),
                  builder: (context, requestSnapshot) {
                    if (requestSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!requestSnapshot.hasData ||
                        requestSnapshot.data!.docs.isEmpty) {
                      return Center(child: Text('No request history.'));
                    }

                    var requests = requestSnapshot.data!.docs;

                    return ListView.builder(
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        var requestData =
                            requests[index].data() as Map<String, dynamic>;
                        var dateRequested =
                            requestData['dateRequested'] as Timestamp;

                        return ListTile(
                          leading: Icon(Icons.description),
                          title: Text('Request ID: ${requests[index].id}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Status: ${requestData['status']}'),
                              Text(
                                  'Date Requested: ${formatTimestamp(dateRequested)}'),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
