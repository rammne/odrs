import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_profile_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> getUsers(String role) {
    // Query users collection based on role
    var query = FirebaseFirestore.instance
        .collection('users')
        .where("role", isEqualTo: role);

    // Filter by student number if search query exists
    if (_searchQuery.isNotEmpty) {
      query = query.where("student_number", isEqualTo: _searchQuery);
    }
    return query.snapshots(includeMetadataChanges: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _isSearching ? _buildSearchField() : _buildAppBarTitle(),
        backgroundColor: Colors.blueGrey[800],
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search,
                color: Colors.white),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _searchQuery = "";
                }
                _isSearching = !_isSearching;
              });
            },
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text('Alumni', style: TextStyle(color: Colors.blueGrey[800])),
                Expanded(
                    child: _buildUserList("alumni", Colors.blueGrey[100]!)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text('Users', style: TextStyle(color: Colors.blueGrey[800])),
                Expanded(child: _buildUserList("user", Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(String role, Color bgColor) {
    return Container(
      color: bgColor,
      child: StreamBuilder<QuerySnapshot>(
        stream: getUsers(role),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                role == "alumni" ? "No Alumni Found" : "No Users Found",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var userData =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              var userId = snapshot.data!.docs[index].id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(userData['name'] ?? 'No name'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userData['email'] ?? 'No email'),
                      Text(
                        'Student #: ${userData['student_number'] ?? 'Alumni'}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AUserProfileScreen(userId: userId),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAppBarTitle() {
    return const Text(
      'User Management',
      style: TextStyle(color: Colors.white),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: "Search by student number...",
        hintStyle: const TextStyle(color: Colors.white70),
        border: InputBorder.none,
        suffixIcon: IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () {
            setState(() {
              _searchQuery = _searchController.text.trim();
            });
          },
        ),
      ),
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      onSubmitted: (value) {
        setState(() {
          _searchQuery = value.trim();
        });
      },
    );
  }
}
