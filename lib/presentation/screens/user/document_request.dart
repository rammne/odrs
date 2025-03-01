import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/pdf_generator.dart';

class DocumentRequestScreen extends StatefulWidget {
  const DocumentRequestScreen({super.key});

  @override
  State<DocumentRequestScreen> createState() => _DocumentRequestScreenState();
}

class _DocumentRequestScreenState extends State<DocumentRequestScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String name = "";
  String role = "";
  String studentNumber = "";
  String contact = "";
  bool isLoading = true;
  String errorMessage = "";

  // Document Request Data
  String? _selectedDocument;
  int _quantity = 1;
  String _otherDocumentText = "";
  String _purposeText = "";
  final TextEditingController _otherController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();

  // Certificate types for dropdown
  final List<String> _certificateTypes = [
    "Certificate of Graduation",
    "Certificate of Completion",
    "Certificate of Enrollment",
    "Certificate of Attendance",
    "Good Moral Certificate"
  ];
  String? _selectedCertificateType;

  // Main document categories
  final List<String> _documentCategories = [
    "SF10 (F137) For Evaluation",
    "SF10 (F137) Official",
    "Certificate", // This will use the dropdown
    "ESC Certification",
    "Diploma",
    "Assessment of School Fees",
    "Other" // For custom document requests
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _otherController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            // Handle both regular and guest users
            name = data['name'] ??
                '${data['firstName']} ${data['lastName']}'.trim();
            studentNumber = data['student_number'] ?? 'N/A (Alumni)';
            contact = data['contact'] ?? 'Not provided';
            role = data['role'] ?? 'alumni';
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
        errorMessage = "Failed to load user data: ${e.toString()}";
        isLoading = false;
      });
    }
  }

  void _submitRequest() async {
    // Validate input
    if (_selectedDocument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a document")),
      );
      return;
    }

    if (_selectedDocument == "Certificate" &&
        _selectedCertificateType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a certificate type")),
      );
      return;
    }

    if (_selectedDocument == "Other" && _otherDocumentText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please specify the document you need")),
      );
      return;
    }

    if (_purposeText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please specify the purpose of your request")),
      );
      return;
    }

    String finalDocumentName = _selectedDocument == "Certificate"
        ? _selectedCertificateType!
        : (_selectedDocument == "Other"
            ? _otherDocumentText
            : _selectedDocument!);

    try {
      // Show loading indicator
      setState(() {
        isLoading = true;
      });

      // Add the document request
      DocumentReference docRef =
          await _firestore.collection('document_requests').add({
        'userId': _auth.currentUser?.uid,
        'name': name,
        'studentNumber': studentNumber,
        'contact': contact,
        'dateRequested': DateTime.now(),
        'documentName': finalDocumentName,
        'quantity': _quantity,
        'purpose': _purposeText,
        'status': 'Pending',
        'role': role,
      });

      // Generate and show receipt
      await RequestReceiptGenerator.generateReceipt(
        requestId: docRef.id,
        name: name,
        studentNumber: studentNumber,
        contact: contact,
        documents: {finalDocumentName: _quantity},
        requestDate: DateTime.now(),
        purpose: _purposeText,
      );

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request submitted successfully")),
      );

      Navigator.pushReplacementNamed(context, '/user');
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to submit request")),
      );
    }
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
                        "Document Selection",
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
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Select one document type:",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ..._documentCategories
                                  .map((document) =>
                                      _documentRadioTile(document))
                                  .toList(),
                              if (_selectedDocument == "Certificate") ...[
                                const SizedBox(height: 16),
                                const Text(
                                  "Select certificate type:",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedCertificateType,
                                      isExpanded: true,
                                      hint:
                                          const Text("Select certificate type"),
                                      items: _certificateTypes.map((type) {
                                        return DropdownMenuItem<String>(
                                          value: type,
                                          child: Text(type),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedCertificateType = value;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                              if (_selectedDocument == "Other") ...[
                                const SizedBox(height: 16),
                                const Text(
                                  "Please specify the document:",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _otherController,
                                  decoration: InputDecoration(
                                    hintText: "Enter document name",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 16),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _otherDocumentText = value;
                                    });
                                  },
                                ),
                              ],
                              if (_selectedDocument != null) ...[
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    const Text(
                                      "Number of copies:",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Container(
                                      width: 120,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove,
                                                size: 20),
                                            onPressed: () {
                                              setState(() {
                                                if (_quantity > 1) {
                                                  _quantity--;
                                                }
                                              });
                                            },
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                          Expanded(
                                            child: Center(
                                              child: Text(
                                                '$_quantity',
                                                style: const TextStyle(
                                                    fontSize: 16),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon:
                                                const Icon(Icons.add, size: 20),
                                            onPressed: () {
                                              setState(() {
                                                _quantity++;
                                              });
                                            },
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Purpose of Request",
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _purposeController,
                                decoration: InputDecoration(
                                  hintText: "Enter the purpose of your request",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 16),
                                ),
                                maxLines: 3,
                                onChanged: (value) {
                                  setState(() {
                                    _purposeText = value;
                                  });
                                },
                              ),
                            ],
                          ),
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

  Widget _documentRadioTile(String docName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RadioListTile<String>(
        title: Text(docName),
        value: docName,
        groupValue: _selectedDocument,
        onChanged: (String? value) {
          setState(() {
            _selectedDocument = value;
            if (value != "Certificate") {
              _selectedCertificateType = null;
            }
          });
        },
        activeColor: Colors.blueGrey[700],
        contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      ),
    );
  }
}
