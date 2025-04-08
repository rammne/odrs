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
  String _otherCertificateText = "";
  String _purposeText = "";
  String _relationshipToLearner = "";
  String _selectedRelationship = "";
  String _otherRelationship = "";
  final TextEditingController _otherController = TextEditingController();
  final TextEditingController _otherCertificateController =
      TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _relationshipController = TextEditingController();
  final TextEditingController _otherRelationshipController =
      TextEditingController();
  String _referenceNumber = "";
  final TextEditingController _referenceController = TextEditingController();

  // Certificate types for dropdown
  final List<String> _certificateTypes = [
    "Certificate of Graduation",
    "Certificate of Completion",
    "Certificate of Enrollment",
    "Certificate of Attendance",
    "Good Moral Certificate",
    "Other"
  ];
  String? _selectedCertificateType;

  // Document prices
  final Map<String, double> _documentPrices = {
    "SF10 (F137) For Evaluation": 115.0,
    "SF10 (F137) Official": 115.0,
    "Certificate": 65.0,
    "ESC Certification": 65.0,
    "Diploma": 150.0,
    "Assessment of School Fees": 65.0
  };

  // Main document categories
  final List<String> _documentCategories = [
    "SF10 (F137) For Evaluation",
    "SF10 (F137) Official",
    "Certificate",
    "ESC Certification",
    "Diploma",
    "Assessment of School Fees",
    "Other"
  ];

  String _copyType = "Hard Copy";
  final List<String> _copyTypes = ["Hard Copy", "Soft Copy"];

  // Add payment provider options
  String _paymentProvider = "GCash";
  final List<String> _paymentProviders = ["GCash", "BDO", "BPI"];

  // Add this list
  final List<String> _relationshipTypes = [
    "Parent",
    "Guardian",
    "Myself",
    "Other"
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _otherController.dispose();
    _otherCertificateController.dispose();
    _purposeController.dispose();
    _relationshipController.dispose();
    _otherRelationshipController.dispose();
    _referenceController.dispose();
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

  String generateRequestId() {
    // Get current timestamp
    final now = DateTime.now();
    // Format: REQ-YYYYMMDD-HHMMSS-XXXX where X is random number
    final timestamp =
        "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    // "-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}";
    // Generate random 4-digit number
    final random =
        (1000 + DateTime.now().millisecond + DateTime.now().microsecond) %
            10000;
    return "REQ-$timestamp-${random.toString().padLeft(4, '0')}";
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

    if (_selectedDocument == "Certificate" &&
        _selectedCertificateType == "Other" &&
        _otherCertificateText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please specify the other certificate type")),
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

    if (_selectedRelationship.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please select your relationship to the learner")),
      );
      return;
    }

    if (_selectedRelationship == "Other" && _otherRelationship.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please specify your relationship")),
      );
      return;
    }

    if (_relationshipToLearner.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your full name")),
      );
      return;
    }

    if (_referenceNumber.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a reference number")),
      );
      return;
    }

    String finalDocumentName = _selectedDocument == "Certificate"
        ? (_selectedCertificateType == "Other"
            ? _otherCertificateText
            : _selectedCertificateType!)
        : (_selectedDocument == "Other"
            ? _otherDocumentText
            : _selectedDocument!);

    try {
      // Show loading indicator
      setState(() {
        isLoading = true;
      });

      final String requestId = generateRequestId();

      // Add the document request
      DocumentReference docRef =
          await _firestore.collection('document_requests').add({
        'requestId': requestId,
        'userId': _auth.currentUser?.uid,
        'name': name,
        'studentNumber': studentNumber,
        'contact': contact,
        'dateRequested': DateTime.now(),
        'documentName': finalDocumentName,
        'quantity': _quantity,
        'purpose': _purposeText,
        'status': 'Pending',
        'processingLocation': null,
        'cancellationReason': null,
        'role': role,
        'lastUpdated': FieldValue.serverTimestamp(),
        'copyType': _copyType,
        'referenceNumber': _referenceNumber,
        'paymentProvider': _paymentProvider,
        'price': _calculateTotalPrice(),
        'relationshipToLearner': _relationshipToLearner,
        'relationshipType': _selectedRelationship == "Other"
            ? _otherRelationship
            : _selectedRelationship,
      });

      // Generate and show receipt
      await RequestReceiptGenerator.generateReceipt(
        requestId: requestId,
        name: name,
        studentNumber: studentNumber,
        contact: contact,
        documents: {finalDocumentName: _quantity},
        requestDate: DateTime.now(),
        purpose: _purposeText,
        copyType: _copyType,
        referenceNumber: _referenceNumber,
        paymentProvider: _paymentProvider,
        price: _calculateTotalPrice(),
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

  double _calculateTotalPrice() {
    if (_selectedDocument == null) return 0;

    double basePrice = 0;
    if (_selectedDocument == "Certificate") {
      basePrice = _documentPrices["Certificate"] ?? 0;
    } else {
      basePrice = _documentPrices[_selectedDocument!] ?? 0;
    }

    return basePrice * _quantity;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF001184),
        foregroundColor: Color.fromARGB(255, 255, 255, 255),
        title: Text('Request Documents'),
      ),
      body: Container(
        // decoration: BoxDecoration(
        //   gradient: LinearGradient(
        //     begin: Alignment.topLeft,
        //     end: Alignment.bottomRight,
        //     colors: [Color(0xFF001184)],
        //   ),
        // ),
        color: Color(0xFFE5E7ED),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
                ? Center(
                    child: Text(errorMessage,
                        style: const TextStyle(color: Colors.red)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 48),
                        _buildCard(
                          title: 'Personal Information',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _infoRow("Name", name),
                              const Divider(height: 24),
                              _infoRow("Student No.", studentNumber),
                              const Divider(height: 24),
                              _infoRow("Contact No.", contact),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildCard(
                          title: 'Document Selection',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Select document type:",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 16),
                              ..._documentCategories
                                  .map((doc) => _buildDocumentRadio(doc))
                                  .toList(),
                              if (_selectedDocument == "Certificate")
                                _buildCertificateDropdown(),
                              if (_selectedDocument == "Other")
                                _buildOtherDocumentField(),
                              if (_selectedDocument != null)
                                _buildQuantitySelector(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildCard(
                          title: 'Purpose of Request',
                          child: TextFormField(
                            controller: _purposeController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: "Enter the purpose of your request",
                              fillColor: Colors.grey[50],
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.blue[800]!, width: 2),
                              ),
                            ),
                            onChanged: (value) => _purposeText = value,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildCard(
                          title: 'Relationship to Learner',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Note:",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1565C0),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Include your full name, Example: Santos, Juan A.",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  color: const Color(0xFF1565C0),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _relationshipController,
                                maxLines: 1,
                                decoration: InputDecoration(
                                  hintText: "Enter your full name",
                                  fillColor: Colors.grey[50],
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: const Color(0xFF1565C0),
                                        width: 2),
                                  ),
                                ),
                                onChanged: (value) =>
                                    _relationshipToLearner = value,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Select your relationship:",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: const Color(0xFF1565C0),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey[50],
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedRelationship.isEmpty
                                        ? null
                                        : _selectedRelationship,
                                    isExpanded: true,
                                    hint: const Text("Select relationship"),
                                    items: _relationshipTypes.map((type) {
                                      return DropdownMenuItem<String>(
                                        value: type,
                                        child: Text(type),
                                      );
                                    }).toList(),
                                    onChanged: (value) => setState(
                                        () => _selectedRelationship = value!),
                                  ),
                                ),
                              ),
                              if (_selectedRelationship == "Other") ...[
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _otherRelationshipController,
                                  maxLines: 1,
                                  decoration: InputDecoration(
                                    hintText:
                                        "Please specify your relationship",
                                    fillColor: Colors.grey[50],
                                    filled: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: const Color(0xFF1565C0),
                                          width: 2),
                                    ),
                                  ),
                                  onChanged: (value) =>
                                      _otherRelationship = value,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildCard(
                          title: 'Payment Provider',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                "Select payment provider:",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue[800]!,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const SizedBox(height: 8),
                              Text('GCash: 0917 822 7532, Jerry S. Hernandez',
                                  style: TextStyle(color: Colors.blue[800]!)),
                              const SizedBox(height: 8),
                              Text(
                                  'BDO - Concepcion Branch - SAVINGS ACCT, Account Number: 006 518 013 093',
                                  style: TextStyle(color: Colors.blue[800]!)),
                              const SizedBox(height: 8),
                              Text(
                                  'BPI - Concepcion Branch - SAVINGS ACCT, Account Number: 612 106 477 2',
                                  style: TextStyle(color: Colors.blue[800]!)),
                              const SizedBox(height: 8),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey[50],
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _paymentProvider,
                                    isExpanded: true,
                                    items: _paymentProviders.map((provider) {
                                      return DropdownMenuItem<String>(
                                        value: provider,
                                        child: Text(provider),
                                      );
                                    }).toList(),
                                    onChanged: (value) => setState(
                                        () => _paymentProvider = value!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildCard(
                          title: 'Reference Number',
                          child: TextFormField(
                            controller: _referenceController,
                            decoration: InputDecoration(
                              hintText: "Enter your reference number",
                              fillColor: Colors.grey[50],
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.blue[800]!, width: 2),
                              ),
                            ),
                            onChanged: (value) => _referenceNumber = value,
                          ),
                        ),
                        // const SizedBox(height: 24),

                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF001184),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _submitRequest,
                            child: const Text(
                              "Submit Request",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildDocumentRadio(String docName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedDocument == docName
              ? Colors.blue[800]!
              : Colors.grey[300]!,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: RadioListTile<String>(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                docName,
                style: const TextStyle(fontSize: 14),
                softWrap: true,
              ),
            ),
            if (_documentPrices.containsKey(docName))
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  '₱${_documentPrices[docName]?.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        value: docName,
        groupValue: _selectedDocument,
        onChanged: (value) => setState(() {
          _selectedDocument = value;
          if (value != "Certificate") {
            _selectedCertificateType = null;
          }
        }),
        activeColor: Colors.blue[800],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildCertificateDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          "Select certificate type:",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[50],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCertificateType,
              isExpanded: true,
              hint: const Text("Select certificate type"),
              items: _certificateTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) =>
                  setState(() => _selectedCertificateType = value),
            ),
          ),
        ),
        if (_selectedCertificateType == "Other")
          TextFormField(
            controller: _otherCertificateController,
            decoration: InputDecoration(
              hintText: "Enter the other certificate type",
              fillColor: Colors.grey[50],
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue[800]!, width: 2),
              ),
            ),
            onChanged: (value) => _otherCertificateText = value,
          ),
      ],
    );
  }

  Widget _buildOtherDocumentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          "Specify the document:",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _otherController,
          decoration: InputDecoration(
            hintText: "Enter the document name",
            fillColor: Colors.grey[50],
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue[800]!, width: 2),
            ),
          ),
          onChanged: (value) => _otherDocumentText = value,
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
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

  Widget _buildQuantitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Number of copies:",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            Text(
              "Total: ₱${_calculateTotalPrice().toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 16,
                color: Colors.blue[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[50],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.remove, color: Colors.blue[800]),
                onPressed: () {
                  if (_quantity > 1) {
                    setState(() => _quantity--);
                  }
                },
              ),
              const SizedBox(width: 16),
              Text(
                '$_quantity',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(Icons.add, color: Colors.blue[800]),
                onPressed:
                    _quantity >= 3 ? null : () => setState(() => _quantity++),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Copy Type:",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[50],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _copyType,
              isExpanded: true,
              items: _copyTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) => setState(() => _copyType = value!),
            ),
          ),
        ),
      ],
    );
  }
}
