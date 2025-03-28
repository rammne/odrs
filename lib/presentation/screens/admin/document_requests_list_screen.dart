import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:odrs/presentation/screens/admin/deleted_requests_screen.dart';
import 'package:odrs/presentation/screens/admin/completed_requests_screen.dart';
import '../../../utils/pdf_generator.dart';

class DocumentRequestsScreen extends StatefulWidget {
  const DocumentRequestsScreen({super.key});

  @override
  State<DocumentRequestsScreen> createState() => _DocumentRequestsScreenState();
}

class _DocumentRequestsScreenState extends State<DocumentRequestsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime? _selectedDate;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  Stream<QuerySnapshot> getAllRequests() {
    Query query = _firestore.collection('document_requests');

    if (_searchQuery.isNotEmpty) {
      return query.where('requestId', isEqualTo: _searchQuery).snapshots();
    } else {
      query = query.orderBy('lastUpdated', descending: true);

      if (_selectedDate != null) {
        DateTime startOfDay = DateTime(
            _selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
        DateTime endOfDay = startOfDay.add(const Duration(days: 1));
        query = query
            .where('dateRequested', isGreaterThanOrEqualTo: startOfDay)
            .where('dateRequested', isLessThan: endOfDay);
      }

      return query.snapshots();
    }
  }

  void _updateStatus(String docId, String newStatus) async {
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

  void _downloadReceipt(Map<String, dynamic> data) async {
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
        paymentProvider: data['paymentProvider'],
        price: data['price'],
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to download receipt")),
      );
    }
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
        backgroundColor: Color(0xFF1B9CFF),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const CompletedRequestsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const DeletedRequestsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            onPressed: () => _selectDate(context),
          ),
          const SizedBox(width: 10),
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
                    Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;

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
                            _infoRow(
                                "Student No.", data['studentNumber'] ?? ""),
                            _infoRow("Contact", data['contact'] ?? ""),
                            _infoRow(
                                "Date Requested",
                                (data['dateRequested'] as Timestamp?)
                                        ?.toDate()
                                        .toString() ??
                                    "Unknown"),
                            _infoRow(
                                "Last Updated",
                                (data['lastUpdated'] as Timestamp?)
                                        ?.toDate()
                                        .toString() ??
                                    "Not yet updated"),
                            _documentInfo(data),
                            _purposeInfo(data),
                            _infoRow("Status", data['status'] ?? "Unknown"),
                            if (data['status'] == 'Processing' &&
                                data['processingLocation'] != null)
                              _infoRow("Processing Location",
                                  data['processingLocation']),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.download),
                                  onPressed: () => _downloadReceipt(data),
                                  tooltip: 'Download Receipt',
                                ),
                              ],
                            ),
                            _statusButtons(doc.id, data['status'] ?? ""),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    Color? textColor;
    if (label == "Status") {
      switch (value) {
        case 'Pending':
          textColor = Colors.grey;
          break;
        case 'Processing':
          textColor = Colors.green;
          break;
        case 'Ready for Pickup':
          textColor = Colors.amber[700];
          break;
        case 'Completed':
          textColor = Colors.blue;
          break;
        case 'Cancelled':
          textColor = Colors.red;
          break;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(color: textColor),
            ),
          ),
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
          Text(
              "${data['documentName']} (${data['quantity']} copies, ${data['copyType'] ?? 'Original'})"),
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
                      _updateStatus(docId, newValue);
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
}
