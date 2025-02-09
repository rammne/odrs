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

  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _studentNumberController =
      TextEditingController();
  final TextEditingController _courseController = TextEditingController();

  bool _isLoading = false;

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get admin's authentication UID
      final User? adminUser = FirebaseAuth.instance.currentUser;
      if (adminUser == null) {
        throw Exception("Admin not logged in.");
      }

      // Check if the admin is authorized
      final adminSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(adminUser.uid)
          .get();

      if (!adminSnapshot.exists || adminSnapshot.data()?['isAdmin'] != true) {
        throw Exception("Unauthorized: Only admins can register users.");
      }

      // Generate a new Firestore document ID for the user
      final newUserRef = FirebaseFirestore.instance.collection('users').doc();

      await newUserRef.set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'contact': _contactController.text.trim(),
        'student_number': _studentNumberController.text.trim(),
        'course': _courseController.text.trim(),
        'role': 'user', // Default role for new users
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User registered successfully!')),
      );

      // Clear form fields after successful registration
      _nameController.clear();
      _emailController.clear();
      _contactController.clear();
      _studentNumberController.clear();
      _courseController.clear();
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Register New User"),
        backgroundColor: Colors.blueGrey[800],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: "Name"),
                validator: (value) => value!.isEmpty ? "Enter a name" : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty || !value.contains("@")
                    ? "Enter a valid email"
                    : null,
              ),
              TextFormField(
                controller: _contactController,
                decoration: InputDecoration(labelText: "Contact"),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value!.isEmpty ? "Enter a contact number" : null,
              ),
              TextFormField(
                controller: _studentNumberController,
                decoration: InputDecoration(labelText: "Student Number"),
                validator: (value) =>
                    value!.isEmpty ? "Enter a student number" : null,
              ),
              TextFormField(
                controller: _courseController,
                decoration: InputDecoration(labelText: "Course"),
                validator: (value) => value!.isEmpty ? "Enter a course" : null,
              ),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _registerUser,
                      child: Text("Register User"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
