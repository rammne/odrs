import 'package:flutter/material.dart';
import 'package:odrs/presentation/screens/user/u_home.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile profile;
  final BaseUserRepository userRepository;

  const EditProfileScreen({
    super.key,
    required this.profile,
    required this.userRepository,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _contact;
  late String _studentNumber;
  late String _course;
  String? _firstName;
  String? _lastName;
  String? _yearGraduated;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _name = widget.profile.name;
    _contact = widget.profile.contact;
    _studentNumber = widget.profile.studentNumber;
    _course = widget.profile.strand;
    _firstName = widget.profile.firstName;
    _lastName = widget.profile.lastName;
    _yearGraduated = widget.profile.yearGraduated;
  }

  Future<void> _saveProfile() async {
    if (!mounted) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    try {
      _formKey.currentState?.save();

      final updatedProfile = UserProfile(
        uid: widget.profile.uid,
        name:
            widget.profile.role == 'alumni' ? '$_firstName $_lastName' : _name,
        firstName: _firstName,
        lastName: _lastName,
        email: widget.profile.email,
        contact: _contact,
        studentNumber: _studentNumber,
        strand: _course,
        role: widget.profile.role,
        yearGraduated: _yearGraduated,
      );

      await widget.userRepository.updateUserProfile(updatedProfile);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
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
        title: Text(widget.profile.role == 'alumni'
            ? 'Edit Alumni Profile'
            : 'Edit Profile'),
        backgroundColor: Color(0xFF001184),
        foregroundColor: Color.fromARGB(255, 255, 255, 255),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Show different fields based on role
              if (widget.profile.role == 'alumni') ...[
                _buildAlumniFields(),
              ] else ...[
                _buildStudentFields(),
              ],
              const SizedBox(height: 24),
              _isSaving
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _saveProfile,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Changes'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlumniFields() {
    return Column(
      children: [
        TextFormField(
          initialValue: _firstName,
          decoration: const InputDecoration(
            labelText: 'First Name',
            border: OutlineInputBorder(),
          ),
          onSaved: (value) => _firstName = value?.trim(),
          validator: (value) =>
              value == null || value.isEmpty ? 'Enter first name' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _lastName,
          decoration: const InputDecoration(
            labelText: 'Last Name',
            border: OutlineInputBorder(),
          ),
          onSaved: (value) => _lastName = value?.trim(),
          validator: (value) =>
              value == null || value.isEmpty ? 'Enter last name' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _yearGraduated,
          decoration: const InputDecoration(
            labelText: 'Year Graduated',
            border: OutlineInputBorder(),
          ),
          onSaved: (value) => _yearGraduated = value?.trim(),
          validator: (value) =>
              value == null || value.isEmpty ? 'Enter graduation year' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _contact,
          decoration: const InputDecoration(
            labelText: 'Contact Number',
            border: OutlineInputBorder(),
            hintText: '09XXXXXXXXX',
          ),
          keyboardType: TextInputType.phone,
          onSaved: (value) => _contact = value?.trim() ?? "",
          validator: _validateContact,
        ),
      ],
    );
  }

  Widget _buildStudentFields() {
    return Column(
      children: [
        TextFormField(
          initialValue: widget.profile.email,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
          readOnly: true,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _name,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
          onSaved: (value) => _name = value?.trim() ?? "",
          validator: (value) =>
              value == null || value.isEmpty ? 'Enter your name' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _contact,
          decoration: const InputDecoration(
            labelText: 'Contact',
            border: OutlineInputBorder(),
            hintText: '09XXXXXXXXX',
          ),
          keyboardType: TextInputType.phone,
          onSaved: (value) => _contact = value?.trim() ?? "",
          validator: _validateContact,
        ),
        const SizedBox(height: 16),
        TextFormField(
          readOnly: true,
          initialValue: _studentNumber,
          decoration: const InputDecoration(
            labelText: 'Student Number',
            border: OutlineInputBorder(),
          ),
          onSaved: (value) => _studentNumber = value?.trim() ?? "",
          validator: (value) =>
              value == null || value.isEmpty ? 'Enter student number' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          readOnly: true,
          initialValue: _course,
          decoration: const InputDecoration(
            labelText: 'Course',
            border: OutlineInputBorder(),
          ),
          onSaved: (value) => _course = value?.trim() ?? "",
          validator: (value) =>
              value == null || value.isEmpty ? 'Enter course' : null,
        ),
      ],
    );
  }
}
