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
  String _referenceNumber = ""; // Add this new field
  final TextEditingController _referenceController =
      TextEditingController(); // Add this controller

  // SF10 Official text field
  String _sf10OfficialText = "";
  final TextEditingController _sf10OfficialController = TextEditingController();

  // Certificate types for dropdown
  final List<String> _certificateTypes = [
    "Certificate of Graduation",
    "Certificate of Completion",
    "Certificate of Enrollment",
    "Certificate of Attendance",
    "Good Moral Certificate",
    "Other"
  ];
  String _otherCertificateText = "";
  final TextEditingController _otherCertificateController = TextEditingController();
  String? _selectedCertificateType;
  bool _principalSignatory = false;
  bool _guidanceCounselorSignatory = false;

  // Document prices
  final Map<String, double> _documentPrices = {
    "SF10 (F137) For Evaluation": 115.0,
    "SF10 (F137) Official": 115.0,
    "ESC Certification": 65.0,
    "Report Card": 25.0,
    "Certificate of Ranking for Grade 12 batch wide": 65.0,
    "Certificate of Ranking for Grade 12 strand wide": 65.0,
    "Assessment of School Fees": 65.0,
    "Other Certificates": 65.0,
  };

  // Main document categories
  final List<String> _documentCategories = [
    "SF10 (F137) For Evaluation",
    "SF10 (F137) Official",
    "ESC Certification",
    "Report Card",
    "Certificate of Ranking for Grade 12 batch wide",
    "Certificate of Ranking for Grade 12 strand wide",
    "Assessment of School Fees",
    "Other Certificates",
  ];

  String _copyType = "Hard Copy";
  final List<String> _copyTypes = ["Hard Copy", "Soft Copy"];

  // Add payment provider options
  String _paymentProvider = "GCash";
  final List<String> _paymentProviders = ["GCash", "BDO", "BPI"];

  // Method of claiming options
  String _claimingMethod = "Pick-up";
  final List<String> _claimingMethods = ["Pick-up", "Delivery"];

  // Relationship to learner options
  String _relationship = "Myself";
  final List<String> _relationshipTypes = ["Myself","Mother", "Father", "Grandmother", "Grandfather", "Aunt", "Uncle", "Other"];
  String _otherRelationship = "";
  final TextEditingController _otherRelationshipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();

  }

  @override
  void dispose() {
    _otherController.dispose();
    _purposeController.dispose();
    _referenceController.dispose();
    _sf10OfficialController.dispose();
    _otherCertificateController.dispose();
    _otherRelationshipController.dispose();
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
            // Handle both regular and alumni users
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
        _selectedCertificateType == "Good Moral Certificate" &&
        !_principalSignatory &&
        !_guidanceCounselorSignatory) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please select at least one signatory for Good Moral Certificate")),
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

    if (_referenceNumber.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a reference number")),
      );
      return;
    }

    if (_relationship == "Other" && _otherRelationship.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please specify your relationship to the learner")),
      );
      return;
    }

    if (_selectedDocument == "SF10 (F137) Official" && _sf10OfficialText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the requesting school")),
      );
      return;
    }

    String finalDocumentName = _selectedDocument == "Certificate"
        ? (_selectedCertificateType == "Other" ? _otherCertificateText : _selectedCertificateType!)
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
        'claimingMethod': _claimingMethod,
        'role': role,
        'lastUpdated': FieldValue.serverTimestamp(),
        'copyType': _copyType,
        'referenceNumber': _referenceNumber,
        'paymentProvider': _paymentProvider,
        'price': _calculateTotalPrice(), // Add this line to store the price
        'principalSignatory': _selectedCertificateType == "Good Moral Certificate" ? _principalSignatory : null,
        'guidanceCounselorSignatory': _selectedCertificateType == "Good Moral Certificate" ? _guidanceCounselorSignatory : null,
        'sf10OfficialInfo': _selectedDocument == "SF10 (F137) Official" ? _sf10OfficialText : null,
        'relationship': _relationship == "Other" ? _otherRelationship : _relationship
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
        claimingMethod: _claimingMethod,
        requestingSchool: _selectedDocument == "SF10 (F137) Official" ? _sf10OfficialText : null,
        principalSignatory: _selectedDocument == "Certificate" && _selectedCertificateType == "Good Moral Certificate" ? _principalSignatory : null,
        guidanceCounselorSignatory: _selectedDocument == "Certificate" && _selectedCertificateType == "Good Moral Certificate" ? _guidanceCounselorSignatory : null
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
                              if (_selectedDocument == "Other Certificates")
                                _buildCertificateDropdown(),
                              if (_selectedDocument == "Other")
                                _buildOtherDocumentField(),
                              if (_selectedDocument == "SF10 (F137) Official")
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Text(
                                          "Requesting School:",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const Text(
                                          " *",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    TextFormField(
                                      controller: _sf10OfficialController,
                                      decoration: InputDecoration(
                                        hintText: "Enter the name of requesting school",
                                        fillColor: Colors.grey[50],
                                        filled: true,
                                        errorText: _sf10OfficialText.trim().isEmpty ? "Required" : null,
                                        helperText: "Note: Present/Submit an official letter from the requesting school upon claiming the document.",
                                        helperMaxLines: 2,
                                        helperStyle: TextStyle(color: const Color.fromARGB(255, 8, 8, 8)),
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
                                      onChanged: (value) => setState(() => _sf10OfficialText = value),
                                    ),
                                  ],
                                ),
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
                                "Select your relationship:",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...List.generate(_relationshipTypes.length, (index) {
                                final type = _relationshipTypes[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _relationship == type
                                          ? Colors.blue[800]!
                                          : Colors.grey[300]!,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: RadioListTile<String>(
                                    title: Text(type),
                                    value: type,
                                    groupValue: _relationship,
                                    onChanged: (value) => setState(() {
                                      _relationship = value!;
                                      if (value != "Other") {
                                        _otherRelationship = "";
                                        _otherRelationshipController.clear();
                                      }
                                    }),
                                    activeColor: Colors.blue[800],
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 4),
                                  ),
                                );
                              }),
                              if (_relationship == "Other") ...[  
                                const SizedBox(height: 16),
                                Text(
                                  "Specify your relationship:",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _otherRelationshipController,
                                  decoration: InputDecoration(
                                    hintText: "Enter your relationship to the learner",
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
                                  onChanged: (value) => setState(() => _otherRelationship = value),
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
                              const SizedBox(height: 16),
                              Text(
                                  'Note: Send a proof of payment together with your name and student number as the email subject to pscashier@olopsc.edu.ph (Pre-School), gscashier@olopsc.edu.ph (Grade School), hscashier@olopsc.edu.ph (High School)',
                                  style: TextStyle(
                                    color: const Color.fromARGB(255, 10, 10, 10),
                                    fontStyle: FontStyle.italic,
                                  )),
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

                        const SizedBox(height: 24),
                        _buildCard(
                          title: 'Claiming Method',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                "Select method of claiming:",
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
                                    value: _claimingMethod,
                                    isExpanded: true,
                                    items: _claimingMethods.map((method) {
                                      return DropdownMenuItem<String>(
                                        value: method,
                                        child: Text(method[0].toUpperCase() + method.substring(1)),
                                      );
                                    }).toList(),
                                    onChanged: (value) => setState(
                                        () => _claimingMethod = value!),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _claimingMethod == "Delivery" 
                                  ? "Note: Requesting party will do the booking and shoulder the shipping fee"
                                  : "Note: If representative, please bring an authorization letter and a photocopy of valid ID",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
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
          children: [
            Expanded(
              child: Text(
                docName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_documentPrices.containsKey(docName))
              Text(
                '₱${_documentPrices[docName]?.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.bold,
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
                  child: Text(type, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (value) => setState(() {
                _selectedCertificateType = value;
                if (value == "Good Moral Certificate") {
                  _principalSignatory = true;  // Set default selection
                  _guidanceCounselorSignatory = false;
                } else {
                  _principalSignatory = false;
                  _guidanceCounselorSignatory = false;
                }
                if (value != "Other") {
                  _otherCertificateText = "";
                  _otherCertificateController.clear();
                }
              }),
            ),
          ),
        ),
        if (_selectedCertificateType == "Other") ...[  
          const SizedBox(height: 16),
          Text(
            "Specify the certificate type:",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _otherCertificateController,
            decoration: InputDecoration(
              hintText: "Enter the certificate type",
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
            onChanged: (value) => setState(() => _otherCertificateText = value),
          ),
        ],
        if (_selectedCertificateType == "Good Moral Certificate") ...[  
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text("Principal Signatory"),
            value: _principalSignatory,
            onChanged: (bool? value) {
              setState(() {
                _principalSignatory = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: Colors.blue[800],
          ),
          CheckboxListTile(
            title: const Text("Guidance Counselor Signatory"),
            value: _guidanceCounselorSignatory,
            onChanged: (bool? value) {
              setState(() {
                _guidanceCounselorSignatory = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: Colors.blue[800],
          ),
        ],
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

  Widget _buildQuantitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          "Number of copies (max 3):",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() {
                if (_quantity > 1) _quantity--;
              }),
              icon: const Icon(Icons.remove_circle_outline),
              color: Colors.blue[800],
            ),
            Text(
              _quantity.toString(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: () => setState(() {
                if (_quantity < 3) _quantity++;
              }),
              icon: const Icon(Icons.add_circle_outline),
              color: _quantity >= 3 ? Colors.grey : Colors.blue[800],
            ),
          ],
        ),
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

  // Widget _buildQuantitySelector() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const SizedBox(height: 24),
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           Text(
  //             "Number of copies:",
  //             style: TextStyle(
  //               fontSize: 16,
  //               color: Colors.grey[600],
  //             ),
  //           ),
  //           Text(
  //             "Total: ₱${_calculateTotalPrice().toStringAsFixed(2)}",
  //             style: TextStyle(
  //               fontSize: 16,
  //               color: Colors.blue[800],
  //               fontWeight: FontWeight.bold,
  //             ),
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 8),
  //       Container(
  //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //         decoration: BoxDecoration(
  //           border: Border.all(color: Colors.grey[300]!),
  //           borderRadius: BorderRadius.circular(12),
  //           color: Colors.grey[50],
  //         ),
  //         child: Row(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             IconButton(
  //               icon: Icon(Icons.remove, color: Colors.blue[800]),
  //               onPressed: () {
  //                 if (_quantity > 1) {
  //                   setState(() => _quantity--);
  //                 }
  //               },
  //             ),
  //             const SizedBox(width: 16),
  //             Text(
  //               '$_quantity',
  //               style:
  //                   const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //             ),
  //             const SizedBox(width: 16),
  //             IconButton(
  //               icon: Icon(Icons.add, color: Colors.blue[800]),
  //               onPressed: () => setState(() => _quantity++),
  //             ),
  //           ],
  //         ),
  //       ),
  //       const SizedBox(height: 24),
  //       Text(
  //         "Copy Type:",
  //         style: TextStyle(
  //           fontSize: 16,
  //           color: Colors.grey[600],
  //         ),
  //       ),
  //       const SizedBox(height: 8),
  //       Container(
  //         padding: const EdgeInsets.symmetric(horizontal: 16),
  //         decoration: BoxDecoration(
  //           border: Border.all(color: Colors.grey[300]!),
  //           borderRadius: BorderRadius.circular(12),
  //           color: Colors.grey[50],
  //         ),
  //         child: DropdownButtonHideUnderline(
  //           child: DropdownButton<String>(
  //             value: _copyType,
  //             isExpanded: true,
  //             items: _copyTypes.map((type) {
  //               return DropdownMenuItem<String>(
  //                 value: type,
  //                 child: Text(type),
  //               );
  //             }).toList(),
  //             onChanged: (value) => setState(() => _copyType = value!),
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }
}
