import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminRegisterUserScreen extends StatefulWidget {
  @override
  _AdminRegisterUserScreenState createState() =>
      _AdminRegisterUserScreenState();
}

class _AdminRegisterUserScreenState extends State<AdminRegisterUserScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _studentNumberController =
      TextEditingController();

  String? _selectedStrand;
  String? _selectedGradeLevel;

  final List<Map<String, String>> _strands = [
    {
      'value': 'STEM',
      'label': 'STEM (Science, Technology, Engineering and Mathematics)'
    },
    {'value': 'HUMSS', 'label': 'HUMSS (Humanities & Social Sciences)'},
    {'value': 'ABM', 'label': 'ABM (Accountancy, Business & Management)'},
    {
      'value': 'TVL-ICT',
      'label': 'TVL-ICT (Information and Communication Technology)'
    },
    {'value': 'TVL-HE', 'label': 'TVL-HE (Home Economics)'},
    {'value': 'ADT', 'label': 'ADT (Arts and Design Track)'},
  ];

  final List<String> _gradeLevels = [
    'Preschool',
    'Grade 1',
    'Grade 2',
    'Grade 3',
    'Grade 4',
    'Grade 5',
    'Grade 6',
    'Grade 7',
    'Grade 8',
    'Grade 9',
    'Grade 10',
    'Grade 11',
    'Grade 12'
  ];

  bool get _isStrandRequired =>
      _selectedGradeLevel == 'Grade 11' || _selectedGradeLevel == 'Grade 12';

  bool _isLoading = false;

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Verify admin authentication
      final User? adminUser = FirebaseAuth.instance.currentUser;
      if (adminUser == null) throw Exception("Admin not logged in.");

      final String adminUid = adminUser.uid;
      final studentNumber = _studentNumberController.text.trim();
      final email = _emailController.text.trim();

      // Check for existing student number
      final existingUserQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('student_number', isEqualTo: studentNumber)
          .get();

      if (existingUserQuery.docs.isNotEmpty) {
        throw Exception("A user with this student number already exists.");
      }

      final temporaryPassword = '${studentNumber}@temp123';

      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: temporaryPassword,
      );

      final userUid = userCredential.user!.uid;

      // Store user data in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userUid).set({
        'name': _nameController.text.trim(),
        'email': email,
        'contact': _contactController.text.trim(),
        'student_number': studentNumber,
        'grade_level': _selectedGradeLevel,
        'strand': _isStrandRequired ? _selectedStrand : null,
        'role': 'user',
        'uid': userUid,
        'created_by': adminUid,
      });

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      await FirebaseAuth.instance.signOut();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'User registered successfully! A password reset email has been sent.'),
          backgroundColor: Colors.green,
        ),
      );

      _nameController.clear();
      _emailController.clear();
      _contactController.clear();
      _studentNumberController.clear();

      setState(() {
        _selectedGradeLevel = null;
        _selectedStrand = null;
      });

      await Future.delayed(Duration(milliseconds: 500));
    } catch (e) {
      // Handle errors
      print("Error: $e");
      String errorMessage = 'Registration failed';

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'This email is already registered';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address';
            break;
          case 'operation-not-allowed':
            errorMessage = 'Email/password accounts are not enabled';
            break;
          case 'wrong-password':
            errorMessage = 'Admin password is incorrect';
            break;
          case 'user-not-found':
            errorMessage = 'Admin account not found';
            break;
          default:
            errorMessage = 'Error: ${e.message}';
        }
      } else if (e is FirebaseException) {
        errorMessage = 'Firestore Error: ${e.message}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Color(0xFF1B9CFF)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF1B9CFF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF1B9CFF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF1B9CFF), width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        keyboardType: keyboardType,
        validator: validator ??
            (value) => value!.isEmpty ? "This field is required" : null,
      ),
    );
  }

  Widget _buildStrandDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: _selectedStrand,
        decoration: InputDecoration(
          labelText: 'Strand',
          prefixIcon: Icon(Icons.school, color: Color(0xFF1B9CFF)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF1B9CFF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF1B9CFF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF1B9CFF), width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: _strands.map((strand) {
          return DropdownMenuItem<String>(
            value: strand['value'],
            child: Text(strand['label']!),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedStrand = value;
          });
        },
        validator: (value) => value == null ? "Please select a strand" : null,
      ),
    );
  }

  Widget _buildGradeLevelDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: _selectedGradeLevel,
        decoration: InputDecoration(
          labelText: 'Grade Level',
          prefixIcon: Icon(Icons.grade, color: Color(0xFF1B9CFF)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF1B9CFF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF1B9CFF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF1B9CFF), width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: _gradeLevels.map((grade) {
          return DropdownMenuItem<String>(
            value: grade,
            child: Text(grade),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedGradeLevel = value;
            if (!_isStrandRequired) {
              _selectedStrand = null;
            }
          });
        },
        validator: (value) =>
            value == null ? "Please select a grade level" : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Register New User",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF1B9CFF),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.person_add_rounded,
                    size: 80,
                    color: Color(0xFF1B9CFF),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Student Registration',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B9CFF),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),
                  _buildInputField(
                    controller: _nameController,
                    label: "Full Name",
                    hint: "Enter student's full name",
                    icon: Icons.person,
                  ),
                  _buildInputField(
                    controller: _emailController,
                    label: "Email Address",
                    hint: "Enter student's email",
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  _buildInputField(
                    controller: _contactController,
                    label: "Contact Number",
                    hint: "Enter contact number",
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  _buildInputField(
                    controller: _studentNumberController,
                    label: "Student Number",
                    hint: "Enter student ID number",
                    icon: Icons.badge,
                  ),
                  _buildGradeLevelDropdown(),
                  if (_isStrandRequired) _buildStrandDropdown(),
                  SizedBox(height: 32),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _registerUser,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Color(0xFF1B9CFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text("Register Student"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
