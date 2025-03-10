import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class RequestHistoryScreen extends StatelessWidget {
  const RequestHistoryScreen({Key? key}) : super(key: key);

  String formatDate(Timestamp timestamp) {
    return DateFormat('MMMM d, yyyy \'at\' h:mm a').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request History'),
      ),
      body: user == null
          ? const Center(child: Text('Please log in to view your requests.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(
                      'document_requests') // Changed from 'requests' to 'document_requests'
                  .where('userId', isEqualTo: user.uid) // Add this filter
                  .orderBy('dateRequested', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  print('Firestore error: ${snapshot.error}');
                  return const Center(child: Text('Error fetching data.'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  print('DEBUG: No requests found in Firestore.');
                  return const Center(child: Text('No requests found.'));
                }

                final requests = snapshot.data!.docs;

                // Debugging: Print each document
                for (var doc in requests) {
                  print('DEBUG: Retrieved document: ${doc.data()}');
                }

                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final requestData =
                        requests[index].data() as Map<String, dynamic>;

                    // Debugging: Check if `documents` field exists
                    if (!requestData.containsKey('documents')) {
                      print(
                          'DEBUG: Missing "documents" field in Firestore document: $requestData');
                    }

                    final documents =
                        (requestData['documents'] as Map<String, dynamic>?) ??
                            {};
                    final documentsList = documents.entries
                        .map((e) => '${e.key}: ${e.value}')
                        .join('\n');

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(
                            'Request by ${requestData['name'] ?? 'Unknown'}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Student Number: ${requestData['studentNumber'] ?? 'N/A'}'),
                            Text('Contact: ${requestData['contact'] ?? 'N/A'}'),
                            Text('Documents Requested:\n$documentsList'),
                            Text('Status: ${_getStatusText(requestData)}'),
                            Text(
                                'Date Requested: ${formatDate(requestData['dateRequested'])}'),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Icon(
                          getStatusIcon(requestData['status'] ?? 'Pending'),
                          color: getStatusColor(
                              requestData['status'] ?? 'Pending'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  String _getStatusText(Map<String, dynamic> data) {
    String status = data['status'] ?? 'Pending';
    if (status == 'Processing' && data['processingLocation'] != null) {
      return '$status - currently in ${data['processingLocation']}';
    }
    return status;
  }

  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'ready for pickup':
        return Icons.assignment_turned_in;
      case 'processing':
        return Icons.hourglass_empty;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.pending;
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ready for pickup':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
