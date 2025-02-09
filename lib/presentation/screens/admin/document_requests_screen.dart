import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentRequestsScreen extends StatefulWidget {
  const DocumentRequestsScreen({super.key});

  @override
  State<DocumentRequestsScreen> createState() => _DocumentRequestsScreenState();
}

class _DocumentRequestsScreenState extends State<DocumentRequestsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedStatus = "Pending"; // Default filter

  Stream<QuerySnapshot> getAllRequests() {
    return FirebaseFirestore.instance
        .collection('document_requests')
        .snapshots();
  }

  void _updateStatus(String docId, String newStatus) async {
    await _firestore.collection('document_requests').doc(docId).update({
      'status': newStatus,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Admin - Document Requests"),
        backgroundColor: Colors.blueGrey[800],
        actions: [
          DropdownButton<String>(
            value: _selectedStatus,
            dropdownColor: Colors.white,
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() => _selectedStatus = newValue);
              }
            },
            items: ["Pending", "Approved", "Rejected"]
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getAllRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No requests found."));
          }

          return ListView(
            padding: const EdgeInsets.all(10),
            children: snapshot.data!.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow("Name", data['name']),
                      _infoRow("Student No.", data['studentNumber']),
                      _infoRow("Contact", data['contact']),
                      _infoRow(
                          "Date Requested",
                          (data['dateRequested'] as Timestamp)
                              .toDate()
                              .toString()),
                      _documentList(data['documents']),
                      _infoRow("Status", data['status']),
                      const SizedBox(height: 10),
                      _statusButtons(doc.id, data['status']),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Widget _documentList(Map<String, dynamic> documents) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Documents Requested:",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        ...documents.entries
            .map((entry) => Text("${entry.key}: ${entry.value}")),
      ],
    );
  }

  Widget _statusButtons(String docId, String currentStatus) {
    if (currentStatus != "Pending") return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _updateStatus(docId, "Approved"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Approve"),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _updateStatus(docId, "Rejected"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Reject"),
          ),
        ),
      ],
    );
  }
}
