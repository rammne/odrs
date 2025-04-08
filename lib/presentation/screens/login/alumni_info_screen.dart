import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'login_screen.dart';

class AlumniInfoScreen extends StatefulWidget {
  const AlumniInfoScreen({super.key});

  @override
  State<AlumniInfoScreen> createState() => _AlumniInfoScreenState();
}

class _AlumniInfoScreenState extends State<AlumniInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  bool _isSaving = false;

  Future<void> _saveInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackbar('Not authenticated');
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'name':
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        'yearGraduated': _yearController.text.trim(),
        'contact': _contactController.text.trim(), // Add contact
        'role': 'alumni',
        'email':
            '${_firstNameController.text.trim()}.${_lastNameController.text.trim()}@alumni',
      });

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/documentRequest');
      }
    } catch (e) {
      _showSnackbar('Failed to save information');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String? _validateContact(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter contact number';
    }
    if (!RegExp(r'^[0-9]{11}$').hasMatch(value)) {
      return 'Enter valid 11-digit contact number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          },
        ),
        backgroundColor: const Color(0xFF001184),
        title: const Text(
          'Alumni Information',
          style: TextStyle(color: Color(0xFFFFFFFF)),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/olopsc_picture_hehe.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(32),
              width: 450,
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
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Alumni Information',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF001184),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please fill in your details',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildTextField(
                      controller: _firstNameController,
                      label: 'First Name',
                      icon: Icons.person_outline,
                      validator: (value) =>
                          value!.isEmpty ? 'Required field' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _lastNameController,
                      label: 'Last Name',
                      icon: Icons.person_outline,
                      validator: (value) =>
                          value!.isEmpty ? 'Required field' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _yearController,
                      label: 'Year Graduated',
                      icon: Icons.school_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Required field' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _contactController,
                      label: 'Contact Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: _validateContact,
                      hintText: '09XXXXXXXXX',
                    ),
                    const SizedBox(height: 32),
                    _isSaving
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF001184),
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _saveInfo,
                              child: const Text(
                                "Continue",
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
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: TextStyle(color: Colors.grey[600]),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[800]!, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        prefixIcon: Icon(icon, color: Colors.grey[600]),
      ),
    );
  }
}
