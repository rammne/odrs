import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DeletedRequestsScreen extends StatefulWidget {
  const DeletedRequestsScreen({Key? key}) : super(key: key);

  @override
  State<DeletedRequestsScreen> createState() => _DeletedRequestsScreenState();
}

class _DeletedRequestsScreenState extends State<DeletedRequestsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Set<String> _selectedRequests = {};
  bool _isSelectionMode = false;

  String formatDate(Timestamp timestamp) {
    return DateFormat('MMMM d, yyyy \'at\' h:mm a').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            if (_isSelectionMode) {
              setState(() {
                _isSelectionMode = false;
                _selectedRequests.clear();
              });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          _isSelectionMode
              ? '${_selectedRequests.length} Selected'
              : 'Deleted Requests',
          style: TextStyle(color: Color(0xFFFFFFFF)),
        ),
        backgroundColor: Color(0xFF001184),
        actions: [
          if (!_isSelectionMode)
            IconButton(
              icon: Icon(Icons.delete_forever, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSelectionMode = true;
                });
              },
            )
          else ...[
            IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedRequests.clear();
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.delete_forever, color: Colors.white),
              onPressed: _selectedRequests.isEmpty
                  ? null
                  : () => _confirmDelete(context),
            ),
          ],
        ],
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
                      .collection('deleted_requests')
                      .orderBy('deletedAt', descending: true)
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection('deleted_requests')
                      .where('requestId', isEqualTo: _searchQuery)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No deleted requests found'));
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
                        leading: _isSelectionMode
                            ? Checkbox(
                                value: _selectedRequests.contains(doc.id),
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedRequests.add(doc.id);
                                    } else {
                                      _selectedRequests.remove(doc.id);
                                    }
                                  });
                                },
                              )
                            : null,
                        title: Text('Request by ${data['name'] ?? 'Unknown'}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Deleted: ${formatDate(data['deletedAt'])}'),
                            const SizedBox(height: 4),
                            Text(
                              'Reason: ${data['cancellationReason'] ?? 'No reason provided'}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
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
                                _buildInfoRow('Cancellation Reason',
                                    data['cancellationReason']),
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

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Permanent Deletion'),
        content: Text(
          'Are you sure you want to permanently delete ${_selectedRequests.length} selected request(s)? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        for (final requestId in _selectedRequests) {
          final docRef = FirebaseFirestore.instance
              .collection('deleted_requests')
              .doc(requestId);
          batch.delete(docRef);
        }
        await batch.commit();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Successfully deleted ${_selectedRequests.length} request(s)'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _isSelectionMode = false;
            _selectedRequests.clear();
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete requests. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
