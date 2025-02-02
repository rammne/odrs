import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentRequestScreen extends StatefulWidget {
  const DocumentRequestScreen({super.key});

  @override
  State<DocumentRequestScreen> createState() => _DocumentRequestScreenState();
}

class _DocumentRequestScreenState extends State<DocumentRequestScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String name = "";
  String studentNumber = "";
  String contact = "";
  bool isLoading = true;
  String errorMessage = "";

  // Document Request Data
  final Map<String, int> _selectedDocuments = {};

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            name = userDoc['name'] ?? "Unknown";
            studentNumber = userDoc['student_number'] ?? "N/A";
            contact = userDoc['contact'] ?? "No contact info";
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = "User data not found.";
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load user data.";
        isLoading = false;
      });
    }
  }

  void _submitRequest() async {
    if (_selectedDocuments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one document")),
      );
      return;
    }

    try {
      await _firestore.collection('document_requests').add({
        'userId': _auth.currentUser?.uid,
        'name': name,
        'studentNumber': studentNumber,
        'contact': contact,
        'dateRequested': DateTime.now(),
        'documents': _selectedDocuments,
        'status': 'Pending', // Default status
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request submitted successfully")),
      );

      Navigator.pushReplacementNamed(
          context, '/user'); // Return to the previous screen
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to submit request")),
      );
    }
  }

  void _toggleDocument(String docName) {
    setState(() {
      if (_selectedDocuments.containsKey(docName)) {
        _selectedDocuments.remove(docName);
      } else {
        _selectedDocuments[docName] = 1; // Default quantity
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        title: const Text("Request Documents",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey[800],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Text(errorMessage,
                      style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Personal Information",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _infoRow("Name", name),
                              const Divider(height: 16),
                              _infoRow("Student No.", studentNumber),
                              const Divider(height: 16),
                              _infoRow("Contact No.", contact),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Available Documents",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _documentCheckbox("SF10 (F137) For Evaluation"),
                            const Divider(height: 1),
                            _documentCheckbox("SF10 (F137) Official"),
                            const Divider(height: 1),
                            _documentCheckbox(
                                "Certificate of Graduation / Completion"),
                            const Divider(height: 1),
                            _documentCheckbox(
                                "Certificate of Enrollment / Attendance"),
                            const Divider(height: 1),
                            _documentCheckbox("ESC Certification"),
                            const Divider(height: 1),
                            _documentCheckbox(
                                "Diploma / Certificate of Completion"),
                            const Divider(height: 1),
                            _documentCheckbox("Good Moral Certificate"),
                            const Divider(height: 1),
                            _documentCheckbox("Assessment of School Fees"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _submitRequest,
                          child: const Text(
                            "Submit Request",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _documentCheckbox(String docName) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        docName,
        style: const TextStyle(fontSize: 15),
      ),
      trailing: _selectedDocuments.containsKey(docName)
          ? Container(
              width: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 20),
                    onPressed: () {
                      setState(() {
                        if (_selectedDocuments[docName]! > 1) {
                          _selectedDocuments[docName] =
                              _selectedDocuments[docName]! - 1;
                        } else {
                          _selectedDocuments.remove(docName);
                        }
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '${_selectedDocuments[docName]}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: () {
                      setState(() {
                        _selectedDocuments[docName] =
                            (_selectedDocuments[docName] ?? 0) + 1;
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            )
          : Checkbox(
              value: _selectedDocuments.containsKey(docName),
              onChanged: (bool? value) => _toggleDocument(docName),
              activeColor: Colors.blueGrey[700],
            ),
    );
  }
}
