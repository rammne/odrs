import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CompletedRequestsScreen extends StatefulWidget {
  const CompletedRequestsScreen({Key? key}) : super(key: key);

  @override
  State<CompletedRequestsScreen> createState() =>
      _CompletedRequestsScreenState();
}

class _CompletedRequestsScreenState extends State<CompletedRequestsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String formatDate(Timestamp timestamp) {
    return DateFormat('MMMM d, yyyy \'at\' h:mm a').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Requests'),
        backgroundColor: Colors.blueGrey[800],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Document ID',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _searchQuery.isEmpty
                  ? FirebaseFirestore.instance
                      .collection('completed_requests')
                      .orderBy('completedAt', descending: true)
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection('completed_requests')
                      .where('requestId', isEqualTo: _searchQuery)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('No completed requests found'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ExpansionTile(
                        title: Text('Request by ${data['name'] ?? 'Unknown'}'),
                        subtitle: Text(
                            'Completed: ${formatDate(data['completedAt'])}'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow(
                                    'Student Number', data['studentNumber']),
                                _buildInfoRow('Contact', data['contact']),
                                _buildInfoRow('Original Request Date',
                                    formatDate(data['dateRequested'])),
                                const SizedBox(height: 8),
                                const Text(
                                  'Requested Documents:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                _buildDocumentsList(data),
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
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value ?? 'N/A'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList(Map<String, dynamic> data) {
    if (data.containsKey('documents')) {
      final documents = data['documents'] as Map<String, dynamic>;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            documents.entries.map((e) => Text('${e.key}: ${e.value}')).toList(),
      );
    } else if (data.containsKey('documentName') &&
        data.containsKey('quantity')) {
      return Text('${data['documentName']} (${data['quantity']} copies)');
    }
    return const Text('No document information available');
  }
}
