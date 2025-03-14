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
  final TextEditingController _strandController = TextEditingController();

  bool _isLoading = false;

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final User? adminUser = FirebaseAuth.instance.currentUser;
      if (adminUser == null) throw Exception("Admin not logged in.");

      // Store admin user information
      final String adminUid = adminUser.uid;

      final studentNumber = _studentNumberController.text.trim();
      final email = _emailController.text.trim();

      // Check if user with this student number already exists in Firestore
      final existingUserQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('student_number', isEqualTo: studentNumber)
          .get();

      if (existingUserQuery.docs.isNotEmpty) {
        throw Exception("A user with this student number already exists.");
      }

      final temporaryPassword = '${studentNumber}@temp123';

      // Create a secondary Firebase Auth instance to avoid signing out the admin
      // This is optional but can help if you want to avoid the sign in/out flow completely

      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: temporaryPassword,
      );

      final userUid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(userUid).set({
        'name': _nameController.text.trim(),
        'email': email,
        'contact': _contactController.text.trim(),
        'student_number': studentNumber,
        'strand': _strandController.text.trim(),
        'role': 'user',
        'uid': userUid,
        'created_by': adminUid,
      });

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // Simply sign out the newly created user without trying to re-authenticate the admin
      await FirebaseAuth.instance.signOut();

      // The admin should still be authenticated in their session
      // No need to reauthenticate with password

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
      _strandController.clear();

      await Future.delayed(Duration(milliseconds: 500));
    } catch (e) {
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
          prefixIcon: Icon(icon, color: Colors.blueGrey[700]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blueGrey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blueGrey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blueGrey.shade700, width: 2),
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
        backgroundColor: Colors.blueGrey[800],
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
                    color: Colors.blueGrey[700],
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Student Registration',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[900],
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
                  _buildInputField(
                    controller: _strandController,
                    label: "Strand",
                    hint: "Enter student's strand",
                    icon: Icons.school,
                  ),
                  SizedBox(height: 32),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _registerUser,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blueGrey[700],
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
