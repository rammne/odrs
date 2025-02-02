// user_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Data model for user profile
class UserProfile {
  final String name;
  final String email;
  final String contact;
  final String studentNumber;

  UserProfile({
    required this.name,
    required this.email,
    required this.contact,
    required this.studentNumber,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      name: data['name'] ?? "Unknown",
      email: data['email'] ?? "No email",
      contact: data['contact'] ?? "No contact info",
      studentNumber: data['student_number'] ?? "No info",
    );
  }

  factory UserProfile.empty() {
    return UserProfile(
      name: "Unknown",
      email: "No email",
      contact: "No contact info",
      studentNumber: "No info",
    );
  }
}

// Repository for user data
class UserRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  UserRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Future<UserProfile> fetchUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw Exception('User data not found');

      return UserProfile.fromFirestore(userDoc);
    } catch (e) {
      throw Exception('Failed to load user data: $e');
    }
  }
}

// Main screen widget
class UserHomeScreen extends StatelessWidget {
  final UserRepository _userRepository;

  UserHomeScreen({
    Key? key,
    UserRepository? userRepository,
  })  : _userRepository = userRepository ?? UserRepository(),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: UserProfileView(userRepository: _userRepository),
    );
  }
}

// Profile view widget
class UserProfileView extends StatefulWidget {
  final UserRepository userRepository;

  const UserProfileView({
    Key? key,
    required this.userRepository,
  }) : super(key: key);

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  late Future<UserProfile> _userProfileFuture;

  @override
  void initState() {
    super.initState();
    _userProfileFuture = widget.userRepository.fetchUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const _CustomAppBar(),
        SliverFillRemaining(
          child: FutureBuilder<UserProfile>(
            future: _userProfileFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _ErrorView(message: snapshot.error.toString());
              }

              return _ProfileCard(
                  profile: snapshot.data ?? UserProfile.empty());
            },
          ),
        ),
      ],
    );
  }
}

// Custom app bar
class _CustomAppBar extends StatelessWidget {
  const _CustomAppBar();

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Profile'),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.pink[300]!,
                Colors.pink[400]!,
                Colors.pink[500]!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Error view
class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Profile card
class _ProfileCard extends StatelessWidget {
  final UserProfile profile;

  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: Colors.grey[300],
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ProfileAvatar(),
                const SizedBox(height: 24),
                _ProfileInfo(profile: profile),
                const SizedBox(height: 32),
                _ActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Profile avatar
class _ProfileAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        border: Border.all(
          color: Theme.of(context).primaryColor,
          width: 2,
        ),
      ),
      child: Icon(
        Icons.person,
        size: 60,
        color: Theme.of(context).primaryColor,
      ),
    );
  }
}

// Profile information
class _ProfileInfo extends StatelessWidget {
  final UserProfile profile;

  const _ProfileInfo({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoTile(
          icon: Icons.person_outline,
          label: 'Name',
          value: profile.name,
        ),
        const SizedBox(height: 16),
        _InfoTile(
          icon: Icons.email_outlined,
          label: 'Email',
          value: profile.email,
        ),
        const SizedBox(height: 16),
        _InfoTile(
          icon: Icons.phone_outlined,
          label: 'Contact',
          value: profile.contact,
        ),
        SizedBox(height: 16),
        _InfoTile(
          icon: Icons.numbers,
          label: 'Student Number',
          value: profile.studentNumber,
        ),
      ],
    );
  }
}

// Information tile
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Action buttons
class _ActionButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => Navigator.pushNamed(context, '/documentRequest'),
          icon: const Icon(Icons.description),
          label: const Text('Request Documents'),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pushNamed(context, '/editProfile'),
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profile'),
              ),
            ),
            SizedBox(
              width: 8,
            ),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/login', (route) => false);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error signing out: $e')),
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ),
          ],
        )
      ],
    );
  }
}
