import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import '../../../utils/pdf_generator.dart';

class AUserProfileScreen extends StatelessWidget {
  final String userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AUserProfileScreen({required this.userId});

  String formatTimestamp(Timestamp timestamp) {
    return DateFormat('MMM dd, yyyy · hh:mm a').format(timestamp.toDate());
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.grey;
      case 'Processing':
        return Colors.green;
      case 'Ready for Pickup':
        return Colors.amber.shade700;
      case 'Completed':
        return Colors.blue;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(Map<dynamic, dynamic> requestData) {
    String status = requestData['status'] ?? 'Unknown';
    if (status == 'Processing' && requestData['processingLocation'] != null) {
      return '$status - currently in ${requestData['processingLocation']}';
    } else if (status == 'Cancelled' &&
        requestData['cancellationReason'] != null) {
      return '$status - ${requestData['cancellationReason']}';
    }
    return status;
  }

  void _updateStatus(
      BuildContext context, String docId, String newStatus) async {
    if (newStatus == 'Cancelled' || newStatus == 'Completed') {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Warning: Confirm ${newStatus} Status'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Are you sure you want to mark this request as ${newStatus.toLowerCase()}?',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'This action cannot be undone and the status cannot be changed afterwards.',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context, false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text('Yes, mark as $newStatus'),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          );
        },
      );

      if (confirm != true) return;
    }

    if (newStatus == 'Processing') {
      String? location = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          String selectedLocation = 'Registrar\'s Office';
          TextEditingController customLocationController =
              TextEditingController();
          bool isOtherOffice = false;

          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Select Processing Location'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<String>(
                      value: selectedLocation,
                      isExpanded: true,
                      items: [
                        'Registrar\'s Office',
                        'Principal\'s Office',
                        'Guidance Office',
                        'Department Office',
                        'Other Office'
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          selectedLocation = value!;
                          isOtherOffice = value == 'Other Office';
                        });
                      },
                    ),
                    if (isOtherOffice) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: customLocationController,
                        decoration: const InputDecoration(
                          labelText: 'Enter Office Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  TextButton(
                    child: const Text('Confirm'),
                    onPressed: () {
                      String finalLocation = selectedLocation == 'Other Office'
                          ? customLocationController.text.trim()
                          : selectedLocation;
                      Navigator.pop(context, finalLocation);
                    },
                  ),
                ],
              );
            },
          );
        },
      );

      if (location != null && location.isNotEmpty) {
        await _firestore.collection('document_requests').doc(docId).update({
          'status': newStatus,
          'processingLocation': location,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    } else if (newStatus == 'Cancelled') {
      String? reason = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          final TextEditingController reasonController =
              TextEditingController();
          return AlertDialog(
            title: const Text('Cancellation Reason'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please provide a reason for cancellation:'),
                const SizedBox(height: 10),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter reason here',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text('Submit'),
                onPressed: () {
                  if (reasonController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a reason')),
                    );
                    return;
                  }
                  Navigator.pop(context, reasonController.text.trim());
                },
              ),
            ],
          );
        },
      );

      if (reason != null && reason.isNotEmpty) {
        DocumentSnapshot doc =
            await _firestore.collection('document_requests').doc(docId).get();
        Map<String, dynamic> requestData = doc.data() as Map<String, dynamic>;

        await _firestore.collection('deleted_requests').add({
          ...requestData,
          'status': newStatus,
          'cancellationReason': reason,
          'deletedAt': FieldValue.serverTimestamp(),
          'originalDocId': docId,
        });

        await _firestore.collection('document_requests').doc(docId).delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Request cancelled and moved to deleted requests')),
        );
      }
    } else if (newStatus == 'Completed') {
      DocumentSnapshot doc =
          await _firestore.collection('document_requests').doc(docId).get();
      Map<String, dynamic> requestData = doc.data() as Map<String, dynamic>;

      await _firestore.collection('completed_requests').add({
        ...requestData,
        'status': newStatus,
        'completedAt': FieldValue.serverTimestamp(),
        'originalDocId': docId,
      });

      await _firestore.collection('document_requests').doc(docId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Request marked as completed and archived')),
      );
    } else {
      await _firestore.collection('document_requests').doc(docId).update({
        'status': newStatus,
        'processingLocation': null,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  void _downloadReceipt(BuildContext context, Map<String, dynamic> data) async {
    try {
      await RequestReceiptGenerator.generateReceipt(
        requestId: data['requestId'],
        name: data['name'],
        studentNumber: data['studentNumber'],
        contact: data['contact'],
        documents: {data['documentName']: data['quantity']},
        requestDate: (data['dateRequested'] as Timestamp).toDate(),
        purpose: data['purpose'],
        copyType: data['copyType'],
        referenceNumber: data['referenceNumber'],
        paymentProvider: data['paymentProvider'] ?? 'N/A',
        price: (data['price'] ?? 0.0).toDouble(),
        claimingMethod: data['claimingMethod'],
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to download receipt")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('User Profile'),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: FutureBuilder(
        future: _firestore.collection('users').doc(userId).get(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }
          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return _buildErrorState('User not found');
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          final studentNumber = userData['student_number'] ?? 'N/A (Alumni)';

          return Column(
            children: [
              _buildProfileHeader(userData),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Request History'),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Expanded(
                child: _buildRequestList(studentNumber),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> userData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue[100],
            child: Icon(
              Icons.person,
              size: 30,
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userData['name'] ?? 'No name',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userData['email'] ?? 'No email',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.badge, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Student #${userData['student_number'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList(String studentNumber) {
    return StreamBuilder<List<QuerySnapshot>>(
      stream: _getAllRequests(studentNumber),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }
        if (!snapshot.hasData) {
          return _buildEmptyState();
        }

        final activeRequests = snapshot.data![0].docs;
        final completedRequests = snapshot.data![1].docs;
        final deletedRequests = snapshot.data![2].docs;

        final allRequests = [
          ...activeRequests,
          ...completedRequests,
          ...deletedRequests,
        ];

        if (allRequests.isEmpty) {
          return _buildEmptyState();
        }

        // Sort by date (newest first)
        allRequests.sort((a, b) {
          final aDate =
              (a.data() as Map<String, dynamic>)['dateRequested'] as Timestamp;
          final bDate =
              (b.data() as Map<String, dynamic>)['dateRequested'] as Timestamp;
          return bDate.compareTo(aDate);
        });

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: allRequests.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final requestData =
                allRequests[index].data() as Map<String, dynamic>;
            final status = requestData['status'] ?? 'Unknown';
            final date = requestData['dateRequested'] as Timestamp;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.description,
                        color: _getStatusColor(status),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                requestData['documentName'] ??
                                    'Unknown Document',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '${requestData['quantity']} copies · ${requestData['copyType'] ?? 'Original'} copy',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getStatusText(requestData).toUpperCase(),
                                style: TextStyle(
                                  color: _getStatusColor(status),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              formatTimestamp(date),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () => _downloadReceipt(context, requestData),
                      tooltip: 'Download Receipt',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child:
                        _statusButtons(context, allRequests[index].id, status),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _statusButtons(
      BuildContext context, String docId, String currentStatus) {
    final List<String> statusOptions = [
      'Pending',
      'Processing',
      'Ready for Pickup',
      'Completed',
      'Cancelled'
    ];

    final bool isDisabled =
        currentStatus == 'Completed' || currentStatus == 'Cancelled';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AbsorbPointer(
                absorbing: isDisabled,
                child: DropdownButtonFormField<String>(
                  value: currentStatus,
                  decoration: InputDecoration(
                    labelText: isDisabled ? 'Status (Final)' : 'Update Status',
                    border: const OutlineInputBorder(),
                    filled: isDisabled,
                    fillColor: Colors.grey[200],
                  ),
                  items: statusOptions.map((String status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _updateStatus(context, docId, newValue);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Stream<List<QuerySnapshot>> _getAllRequests(String studentNumber) {
    final activeRequests = _firestore
        .collection('document_requests')
        .where('studentNumber', isEqualTo: studentNumber)
        .snapshots();

    final completedRequests = _firestore
        .collection('completed_requests')
        .where('studentNumber', isEqualTo: studentNumber)
        .snapshots();

    final deletedRequests = _firestore
        .collection('deleted_requests')
        .where('studentNumber', isEqualTo: studentNumber)
        .snapshots();
    return CombineLatestStream.list(
        [activeRequests, completedRequests, deletedRequests]);
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading data...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No requests found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
