import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_profile_screen.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  Future<AggregateQuerySnapshot> getUserCount() {
    return FirebaseFirestore.instance
        .collection('users')
        .where("role", isEqualTo: "user")
        .count()
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: FutureBuilder<AggregateQuerySnapshot>(
          future: getUserCount(),
          builder: (context, snapshot) {
            int? userCount = snapshot.hasData ? snapshot.data!.count : 0;
            return Row(
              children: [
                const Text('User Management'),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Total: $userCount',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            );
          },
        ),
        backgroundColor: Colors.blueGrey[800],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where("role", isEqualTo: "user")
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found'));
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
                  subtitle: Text(userData['email'] ?? 'No email'),
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
}
