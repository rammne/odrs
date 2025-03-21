import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Reports'),
        backgroundColor: const Color(0xFF1B9CFF),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data!.docs;

          if (reports.isEmpty) {
            return const Center(child: Text('No reports found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index].data() as Map<String, dynamic>;
              final createdAt = report['createdAt'] as Timestamp?;
              final formattedDate = createdAt != null
                  ? DateFormat('MMM dd, yyyy HH:mm').format(createdAt.toDate())
                  : 'Date not available';

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  title: Text(
                    report['title'] ?? 'No title',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    'Reported by: ${report['userEmail']}\n$formattedDate',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Description:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            report['description'] ?? 'No description provided',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Status: ${report['status']}',
                                style: TextStyle(
                                  color: _getStatusColor(report['status']),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (String newStatus) {
                                  _updateReportStatus(
                                      reports[index].reference, newStatus);
                                },
                                itemBuilder: (BuildContext context) => [
                                  const PopupMenuItem(
                                    value: 'pending',
                                    child: Text('Mark as Pending'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'in_progress',
                                    child: Text('Mark as In Progress'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'resolved',
                                    child: Text('Mark as Resolved'),
                                  ),
                                ],
                                child: Chip(
                                  label: const Text('Update Status'),
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  labelStyle:
                                      const TextStyle(color: Colors.white),
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
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateReportStatus(
      DocumentReference reportRef, String newStatus) async {
    try {
      await reportRef.update({'status': newStatus});
    } catch (e) {
      print('Error updating report status: $e');
    }
  }
}
