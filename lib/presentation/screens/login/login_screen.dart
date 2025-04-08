import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _requestIdController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _showSearch = false;
  bool _isSearching = false;
  bool _showPassword = false;
  Map<String, dynamic>? _requestDetails;
  String? _searchError;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackbar("Please fill in all fields.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final User? user = userCredential.user;
      if (user == null) {
        _showSnackbar("Authentication failed.");
        return;
      }

      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        _showSnackbar("User profile not found.");
        return;
      }

      final data = userDoc.data() as Map<String, dynamic>?;
      final String role = data?['role'] as String? ?? 'user';

      if (mounted) {
        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacementNamed(context, '/user');
        }
      }
    } on FirebaseAuthException catch (e) {
      _showSnackbar(e.message ?? "Login failed.");
    } catch (e) {
      _showSnackbar("An unexpected error occurred.");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loginAnonymously() async {
    setState(() => _isLoading = true);
    try {
      await _auth.signInAnonymously();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/guestInfo');
      }
    } catch (e) {
      _showSnackbar("Anonymous login failed.");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _forgotPassword() async {
    final TextEditingController resetEmailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email address to reset your password.'),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (resetEmailController.text.isEmpty) {
                _showSnackbar('Please enter your email address.');
                return;
              }

              try {
                // Check if email exists in users collection
                final QuerySnapshot result = await FirebaseFirestore.instance
                    .collection('users')
                    .where('email', isEqualTo: resetEmailController.text.trim())
                    .limit(1)
                    .get();

                if (result.docs.isEmpty) {
                  if (mounted) {
                    Navigator.pop(context);
                    _showSnackbar('No account found with this email address.');
                  }
                  return;
                }

                // If email exists, send reset link
                await _auth.sendPasswordResetEmail(
                  email: resetEmailController.text.trim(),
                );

                if (mounted) {
                  Navigator.pop(context);
                  _showSnackbar(
                    'Password reset link sent to your email address.',
                  );
                }
              } on FirebaseAuthException catch (e) {
                Navigator.pop(context);
                _showSnackbar(e.message ?? 'Failed to send reset email.');
              } catch (e) {
                Navigator.pop(context);
                _showSnackbar('An error occurred. Please try again.');
              }
            },
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );
  }

  Future<void> _searchRequest() async {
    final String requestId = _requestIdController.text.trim();
    if (requestId.isEmpty) {
      setState(() {
        _searchError = "Please enter a Request ID";
        _requestDetails = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
      _requestDetails = null;
    });

    try {
      // Search in document_requests collection
      final activeDoc = await FirebaseFirestore.instance
          .collection('document_requests')
          .where('requestId', isEqualTo: requestId)
          .limit(1)
          .get();

      if (activeDoc.docs.isNotEmpty) {
        setState(() {
          _requestDetails = {
            ...activeDoc.docs.first.data(),
            'collection': 'document_requests',
          };
          _isSearching = false;
        });
        return;
      }

      // Search in completed_requests collection
      final completedDoc = await FirebaseFirestore.instance
          .collection('completed_requests')
          .where('requestId', isEqualTo: requestId)
          .limit(1)
          .get();

      if (completedDoc.docs.isNotEmpty) {
        setState(() {
          _requestDetails = {
            ...completedDoc.docs.first.data(),
            'collection': 'completed_requests',
          };
          _isSearching = false;
        });
        return;
      }

      // Search in deleted_requests collection
      final deletedDoc = await FirebaseFirestore.instance
          .collection('deleted_requests')
          .where('requestId', isEqualTo: requestId)
          .limit(1)
          .get();

      if (deletedDoc.docs.isNotEmpty) {
        setState(() {
          _requestDetails = {
            ...deletedDoc.docs.first.data(),
            'collection': 'deleted_requests',
          };
          _isSearching = false;
        });
        return;
      }

      // Document not found in any collection
      setState(() {
        _searchError = "Request not found";
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchError = "Error searching for request: ${e.toString()}";
        _isSearching = false;
      });
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildRequestDetailsCard() {
    if (_requestDetails == null) return const SizedBox.shrink();

    String statusText;
    Color statusColor;

    // Determine status based on collection
    final String collection = _requestDetails!['collection'] as String;

    switch (collection) {
      case 'completed_requests':
        statusText = "Completed";
        statusColor = Colors.green;
        break;
      case 'deleted_requests':
        statusText = "Cancelled";
        statusColor = Colors.red;
        break;
      case 'document_requests':
        final String status =
            _requestDetails!['status'] as String? ?? 'Unknown';
        statusText = status;
        switch (status.toLowerCase()) {
          case 'pending':
            statusColor = Colors.orange;
            break;
          case 'processing':
            statusColor = Colors.blue;
            break;
          case 'approved':
            statusColor = Colors.teal;
            break;
          case 'rejected':
            statusColor = Colors.red;
            break;
          default:
            statusColor = Colors.grey;
        }
        break;
      default:
        statusText = "Unknown";
        statusColor = Colors.grey;
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildDetailRow(
                'Request ID', _requestDetails!['requestId'] ?? 'N/A'),
            _buildDetailRow(
                'Document Type', _requestDetails!['documentName'] ?? 'N/A'),
            _buildDetailRow('Requested By', _requestDetails!['name'] ?? 'N/A'),
            _buildDetailRow('Date Requested',
                _formatTimestamp(_requestDetails!['dateRequested'])),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Status: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (_requestDetails!['remarks'] != null &&
                _requestDetails!['remarks'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _buildDetailRow('Remarks', _requestDetails!['remarks']),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      if (timestamp is Timestamp) {
        final DateTime dateTime = timestamp.toDate();
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else {
        return timestamp.toString();
      }
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/olopsc2.png'),
            fit: BoxFit.cover,
            opacity: .8,
            filterQuality: FilterQuality.high,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(32),
              width: 450,
              decoration: BoxDecoration(
                color: const Color.fromARGB(190, 255, 255, 255),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    "images/odrs-logo-nb.png",
                    height: 300,
                  ),
                  Text(
                    'Please sign in to continue',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _textField("Email", _emailController, false),
                  const SizedBox(height: 20),
                  _textField("Password", _passwordController, true),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _forgotPassword,
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(color: Colors.blue[800]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : Column(
                          children: [
                            SizedBox(
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
                                onPressed: _login,
                                child: const Text(
                                  "Sign In",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      color: const Color(0xFF001184)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _loginAnonymously,
                                child: Text(
                                  "Continue as Guest",
                                  style: TextStyle(
                                    color: const Color(0xFF001184),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton.icon(
                                icon: Icon(
                                  Icons.search,
                                  color: const Color(0xFF001184),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      color: const Color(0xFF001184)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showSearch = !_showSearch;
                                    if (!_showSearch) {
                                      _requestIdController.clear();
                                      _requestDetails = null;
                                      _searchError = null;
                                    }
                                  });
                                },
                                label: Text(
                                  "Quick Search",
                                  style: TextStyle(
                                    color: const Color(0xFF001184),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                  if (_showSearch) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Track Your Document Request',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF001184),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _requestIdController,
                      decoration: InputDecoration(
                        labelText: "Request ID",
                        hintText: "Enter your request ID",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.description_outlined),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _searchRequest,
                        ),
                      ),
                      onSubmitted: (_) => _searchRequest(),
                    ),
                    if (_isSearching)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    if (_searchError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          _searchError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    _buildRequestDetailsCard(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField(
      String label, TextEditingController controller, bool isPassword) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_showPassword,
      style: const TextStyle(fontSize: 16),
      onFieldSubmitted: (_) => _login(),
      decoration: InputDecoration(
        labelText: label,
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
        prefixIcon: Icon(
          isPassword ? Icons.lock_outline : Icons.email_outlined,
          color: Colors.grey[600],
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey[600],
                ),
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
              )
            : null,
      ),
    );
  }
}
