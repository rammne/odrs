import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
    }
    return status;
  }

  void _updateStatus(
      BuildContext context, String docId, String newStatus) async {
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
    } else {
      await _firestore.collection('document_requests').doc(docId).update({
        'status': newStatus,
        'processingLocation': null,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
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
    return StreamBuilder(
      stream: _firestore
          .collection('document_requests')
          .where('studentNumber', isEqualTo: studentNumber)
          .snapshots(),
      builder: (context, requestSnapshot) {
        if (requestSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }
        if (!requestSnapshot.hasData || requestSnapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final requests = requestSnapshot.data!.docs;

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final request = requests[index];
            final requestData = request.data() as Map;
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
                    title: Text(
                      requestData['documentName'] ?? 'Unknown Document',
                      style: const TextStyle(fontWeight: FontWeight.w500),
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
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(
                        labelText: 'Update Status',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        'Pending',
                        'Processing',
                        'Ready for Pickup',
                        'Completed',
                        'Cancelled'
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          _updateStatus(context, request.id, newValue);
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
