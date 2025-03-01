import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentRequestsScreen extends StatefulWidget {
  const DocumentRequestsScreen({super.key});

  @override
  State<DocumentRequestsScreen> createState() => _DocumentRequestsScreenState();
}

class _DocumentRequestsScreenState extends State<DocumentRequestsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime? _selectedDate;

  Stream<QuerySnapshot> getAllRequests() {
    Query query = _firestore
        .collection('document_requests')
        .orderBy('dateRequested', descending: true);

    if (_selectedDate != null) {
      DateTime startOfDay = DateTime(
          _selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
      DateTime endOfDay = startOfDay.add(const Duration(days: 1));
      query = query
          .where('dateRequested', isGreaterThanOrEqualTo: startOfDay)
          .where('dateRequested', isLessThan: endOfDay);
    }

    return query.snapshots(includeMetadataChanges: true);
  }

  void _updateStatus(String docId, String newStatus) async {
    await _firestore
        .collection('document_requests')
        .doc(docId)
        .update({'status': newStatus});
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Admin - Document Requests",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            onPressed: () => _selectDate(context),
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
                      _infoRow("Name", data['name'] ?? ""),
                      _infoRow("Student No.", data['studentNumber'] ?? ""),
                      _infoRow("Contact", data['contact'] ?? ""),
                      _infoRow(
                          "Date Requested",
                          (data['dateRequested'] as Timestamp?)
                                  ?.toDate()
                                  .toString() ??
                              "Unknown"),
                      _documentInfo(data),
                      _purposeInfo(data),
                      _infoRow("Status", data['status'] ?? "Unknown"),
                      const SizedBox(height: 10),
                      _statusButtons(doc.id, data['status'] ?? ""),
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

  Widget _documentInfo(Map<String, dynamic> data) {
    if (data.containsKey('documentName') && data.containsKey('quantity')) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8.0, bottom: 4.0),
            child: Text("Document Requested:",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Text("${data['documentName']} (${data['quantity']} copies)"),
        ],
      );
    } else if (data.containsKey('documents')) {
      Map<String, dynamic>? documents =
          data['documents'] as Map<String, dynamic>?;
      if (documents == null || documents.isEmpty) {
        return const Text("No documents requested");
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8.0, bottom: 4.0),
            child: Text("Documents Requested:",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...documents.entries
              .map((entry) => Text("${entry.key}: ${entry.value}")),
        ],
      );
    } else {
      return const Text("No document information available");
    }
  }

  Widget _purposeInfo(Map<String, dynamic> data) {
    if (!data.containsKey('purpose') || data['purpose'] == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 8.0, bottom: 4.0),
          child:
              Text("Purpose:", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Text(data['purpose']),
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
