import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:odrs/presentation/screens/admin/user_profile_screen.dart';
import 'package:odrs/presentation/screens/user/u_home.dart';

class UserManagementScreen extends StatelessWidget {
  UserManagementScreen({super.key});

  final userRepository = UserRepository();

  Stream<QuerySnapshot> getUsers() {
    print('Fetching users from Firestore...'); // Debug print
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'user') // Only fetch users with role = "user"
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: getUsers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Error: ${snapshot.error}'); // Debug print
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          print('No data received from Firestore'); // Debug print
          return const Center(child: Text("No data received from Firestore"));
        }

        print(
            'Number of documents: ${snapshot.data!.docs.length}'); // Debug print

        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No users found."));
        }

        return ListView(
          padding: const EdgeInsets.all(10),
          children: snapshot.data!.docs.map((doc) {
            Map<String, dynamic> user = doc.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(user['name'] ?? 'Unknown'),
                subtitle: Text(user['email'] ?? 'No email'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AUserProfileScreen(userId: doc.id),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
