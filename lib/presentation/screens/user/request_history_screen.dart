import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:odrs/utils/pdf_generator.dart';

class RequestHistoryScreen extends StatelessWidget {
  const RequestHistoryScreen({Key? key}) : super(key: key);

  String formatDate(Timestamp timestamp) {
    return DateFormat('MMMM d, yyyy \'at\' h:mm a').format(timestamp.toDate());
  }

  String _getSignatoriesText(Map<String, dynamic> requestData) {
    final hasPrincipal = requestData['principalSignatory'] != null;
    final hasGuidance = requestData['guidanceCounselorSignatory'] != null;

    if (hasPrincipal && hasGuidance) {
      return 'Principal and Guidance Counselor';
    } else if (hasPrincipal) {
      return 'Principal';
    } else if (hasGuidance) {
      return 'Guidance Counselor';
    }
    return 'None';
  }

  Stream<List<QuerySnapshot>> getAllUserRequests(String userId) {
    final activeRequests = FirebaseFirestore.instance
        .collection('document_requests')
        .where('userId', isEqualTo: userId)
        .snapshots();

    final completedRequests = FirebaseFirestore.instance
        .collection('completed_requests')
        .where('userId', isEqualTo: userId)
        .snapshots();

    final deletedRequests = FirebaseFirestore.instance
        .collection('deleted_requests')
        .where('userId', isEqualTo: userId)
        .snapshots();
    return CombineLatestStream.list([
      activeRequests,
      completedRequests,
      deletedRequests,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Color(0xFFCACACA),
      appBar: AppBar(
        leading: IconButton(
            color: Colors.white,
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back)),
        backgroundColor: Color(0xFF001184),
        title: const Text(
          'Request History',
          style: TextStyle(color: Color.fromARGB(255, 255, 247, 247)),
        ),
      ),
      body: user == null
          ? const Center(child: Text('Please log in to view your requests.'))
          : StreamBuilder<List<QuerySnapshot>>(
              stream: getAllUserRequests(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Error fetching data.'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: Text('No requests found.'));
                }

                final activeRequests = snapshot.data![0].docs;
                final completedRequests = snapshot.data![1].docs;
                final deletedRequests = snapshot.data![2].docs;

                final allRequests = [
                  ...activeRequests,
                  ...completedRequests,
                  ...deletedRequests,
                ];

                // Sort by date (newest first)
                allRequests.sort((a, b) {
                  final aDate = (a.data()
                      as Map<String, dynamic>)['dateRequested'] as Timestamp;
                  final bDate = (b.data()
                      as Map<String, dynamic>)['dateRequested'] as Timestamp;
                  return bDate.compareTo(aDate);
                });

                if (allRequests.isEmpty) {
                  return const Center(child: Text('No requests found.'));
                }

                return ListView.builder(
                  itemCount: allRequests.length,
                  itemBuilder: (context, index) {
                    final requestData =
                        allRequests[index].data() as Map<String, dynamic>;
                    print('DEBUG: Full request data: $requestData');
                    if (!requestData.containsKey('documents')) {
                      print(
                          'DEBUG: Missing "documents" field in Firestore document: $requestData');
                    }

                    final documentName = requestData['documentName'] ?? '';
                    final quantity = requestData['quantity']?.toString() ?? '';
                    final copyType = requestData['copyType'] ?? 'Original';
                    final documentsList = '$documentName: $quantity ($copyType)';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(
                                'Request by ${requestData['name'] ?? 'Unknown'}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('First Name: ${requestData['firstName'] ?? 'N/A'}'),
                                Text('Last Name: ${requestData['lastName'] ?? 'N/A'}'),
                                Text('Relationship: ${requestData['relationship'] ?? 'N/A'}'),
                                Text(
                                    'Student Number: ${requestData['studentNumber'] ?? 'N/A'}'),
                                Text(
                                    'Contact: ${requestData['contact'] ?? 'N/A'}'),
                                if (requestData['sf10OfficialInfo'] != null)
                                  Text('Requesting School: ${requestData['sf10OfficialInfo']}'),
                                Text('Document Requested:\n$documentsList'),
                                if (requestData['principalSignatory'] != null || requestData['guidanceCounselorSignatory'] != null)
                                  Text('Signatories: ${_getSignatoriesText(requestData)}'),
                                Text(
                                    'Date Requested: ${formatDate(requestData['dateRequested'])}'),
                                Text(
                                    '\n\nStatus: ${_getStatusText(requestData)}',
                                    style: TextStyle(
                                        color: getStatusColor(
                                            requestData['status'] ?? 'Pending'),
                                        fontWeight: FontWeight.bold)),
                                if (requestData['status'] == 'Cancelled' &&
                                    requestData['cancellationReason'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      'Cancellation Reason: ${requestData['cancellationReason']}',
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: Icon(
                              getStatusIcon(requestData['status'] ?? 'Pending'),
                              color: getStatusColor(
                                  requestData['status'] ?? 'Pending'),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: 8.0, right: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.receipt_long),
                                  label: const Text('View Ticket'),
                                  onPressed: () {
                                    RequestReceiptGenerator.showReceipt(
                                      requestId: requestData['requestId'],
                                      name: requestData['name'] ?? 'Unknown',
                                      studentNumber:
                                          requestData['studentNumber'] ?? 'N/A',
                                      contact: requestData['contact'] ?? 'N/A',
                                      documents: {
                                        requestData['documentName']:
                                            requestData['quantity']
                                      },
                                      requestDate:
                                          requestData['dateRequested'].toDate(),
                                      purpose: requestData['purpose'] ??
                                          'Not specified',
                                      copyType:
                                          requestData['copyType'] ?? 'Original',
                                      referenceNumber:
                                          requestData['referenceNumber'] ??
                                              'N/A',
                                      paymentProvider:
                                          requestData['paymentProvider'] ??
                                              'N/A',
                                      price: (requestData['price'] ?? 0.0)
                                          .toDouble(),
                                      claimingMethod: requestData['claimingMethod'] ?? 'Pick-up',
                                      requestingSchool: requestData['sf10OfficialInfo'],
                                      principalSignatory: requestData['principalSignatory'],
                                      guidanceCounselorSignatory: requestData['guidanceCounselorSignatory'],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
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
    } else if (status == 'Cancelled' && data['cancellationReason'] != null) {
      return '$status - ${data['cancellationReason']}';
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
