import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:odrs/presentation/screens/user/document_request.dart';
import 'package:odrs/presentation/screens/user/edit_screen.dart';
import 'package:odrs/presentation/screens/user/profile_page.dart';
import 'package:odrs/presentation/screens/user/report_screen.dart';
import 'package:odrs/presentation/screens/user/request_history_screen.dart';
import 'package:odrs/presentation/screens/user/help_screen.dart';

class UserProfile {
  final String uid;
  final String name;
  final String? firstName; // New field for alumni
  final String? lastName; // New field for alumni
  final String email;
  final String contact;
  final String studentNumber;
  final String strand; // Changed from course
  final String role;
  final String? yearGraduated; // New field for alumni
  final DateTime? lastCourseEditDate; // Track when course was last edited

  UserProfile({
    required this.uid,
    required this.name,
    this.firstName,
    this.lastName,
    required this.email,
    required this.contact,
    required this.studentNumber,
    required this.strand, // Changed from course
    required this.role,
    this.yearGraduated,
    this.lastCourseEditDate,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      name: data['name'] ?? '',
      firstName: data['firstName'],
      lastName: data['lastName'],
      email: data['email'] ?? '',
      contact: data['contact'] ?? '',
      studentNumber: data['student_number'] ?? '',
      strand: data['strand'] ?? 'Undefined', // Changed from course
      role: data['role'] ?? 'user',
      yearGraduated: data['yearGraduated'],
      lastCourseEditDate: data['lastCourseEditDate'] != null ? (data['lastCourseEditDate'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'contact': contact,
        'student_number': studentNumber,
        'strand': strand, // Changed from course
        'role': role,
        'yearGraduated': yearGraduated,
        'lastCourseEditDate': lastCourseEditDate != null ? Timestamp.fromDate(lastCourseEditDate!) : null,
      };

  UserProfile copyWith({
    String? name,
    String? contact,
    String? studentNumber,
    String? strand, // Changed from course
  }) {
    return UserProfile(
      uid: uid,
      name: name ?? this.name,
      email: email,
      contact: contact ?? this.contact,
      studentNumber: studentNumber ?? this.studentNumber,
      strand: strand ?? this.strand, // Changed from course
      role: role,
    );
  }
}

abstract class BaseUserRepository {
  Future<UserProfile> fetchUserProfile();
  Future<void> updateUserProfile(UserProfile profile);
}

class UserRepository implements BaseUserRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<UserProfile> fetchUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Authentication required');

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) throw Exception('User profile not found');

    return UserProfile.fromFirestore(doc);
  }

  @override
  Future<void> updateUserProfile(UserProfile profile) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('No authenticated user found');

    final updateData = {
      'name': profile.name,
      'contact': profile.contact,
      'student_number': profile.studentNumber,
      'strand': profile.strand, // Changed from course
    };

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update(updateData);
    } on FirebaseException catch (e) {
      throw Exception('Firebase error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }
}

class UserProfileScreen extends StatefulWidget {
  final BaseUserRepository userRepository;

  const UserProfileScreen({super.key, required this.userRepository});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late Future<UserProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = widget.userRepository.fetchUserProfile();
  }

  void _refreshProfile() {
    setState(() => _profileFuture = widget.userRepository.fetchUserProfile());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE5E7ED),
      drawer: FutureBuilder<UserProfile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();
          return _buildNavigationDrawer(context, snapshot.data!);
        },
      ),
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Color(0xFF001184),
        foregroundColor: Color.fromARGB(255, 255, 255, 255),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshProfile(),
        child: FutureBuilder<UserProfile>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingIndicator();
            }
            if (snapshot.hasError) {
              return _ErrorSection(
                error: snapshot.error.toString(),
                onRetry: _refreshProfile,
              );
            }

            final profile = snapshot.data!;
            return _buildMainContent(profile);
          },
        ),
      ),
    );
  }

  Widget _buildNavigationDrawer(BuildContext context, UserProfile profile) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          InkWell(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(profile: profile),
                ),
              );
            },
            child: UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF001184),
              ),
              accountName: Text(
                profile.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              accountEmail: Text(profile.email),
              currentAccountPicture: Hero(
                tag: 'profile_avatar',
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    profile.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      color: Color(0xFF001184),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // ListTile(
          //   leading: const Icon(Icons.home),
          //   title: const Text('Home'),
          //   onTap: () {
          //     Navigator.pop(context);
          //     if (ModalRoute.of(context)?.settings.name != '/') {
          //       Navigator.pushReplacementNamed(context, '/');
          //     }
          //   },
          // ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Request Documents'),
            onTap: () {
              Navigator.pop(context);
              _navigateToDocumentRequestScreen();
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Request History'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RequestHistoryScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Profile'),
            onTap: () {
              Navigator.pop(context);
              _navigateToEditScreen(profile);
            },
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Report'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(UserProfile profile) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // Welcome Card
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * .8,
                    height: MediaQuery.of(context).size.height * .78,
                    padding: const EdgeInsets.all(24),
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
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor:
                                    const Color(0xFF001184).withOpacity(0.1),
                                child: Text(
                                  profile.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF001184),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome, ${profile.name}!',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      profile.studentNumber,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Online Document Request System',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF001184),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Welcome to our Online Document Request System! This platform allows you to:',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFeatureItem(
                            icon: Icons.description_outlined,
                            text: 'Request academic documents easily',
                          ),
                          _buildFeatureItem(
                            icon: Icons.history,
                            text: 'Track your document requests',
                          ),
                          _buildFeatureItem(
                            icon: Icons.access_time,
                            text: 'Save time with online processing',
                          ),
                          SizedBox(
                            height: 24,
                          ),
                          Center(
                            child: Image(
                              image: AssetImage('images/olopsccover.png'),
                            ),
                          ),
                          SizedBox(
                            height: 24,
                          ),
                          // Request Document Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _navigateToDocumentRequestScreen,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF001184),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.description),
                                  SizedBox(width: 12),
                                  Text(
                                    'Request Documents',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF001184).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF001184),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEditScreen(UserProfile profile) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          profile: profile,
          userRepository: widget.userRepository,
        ),
      ),
    );

    if (result == true) {
      _refreshProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  void _navigateToDocumentRequestScreen() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentRequestScreen(),
        ));
  }
}

class _ProfileAppBar extends StatelessWidget {
  const _ProfileAppBar();

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 150,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Profile'),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColorDark,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onEditPressed;
  final VoidCallback onRequestDocumentsPressed;

  const _ProfileContent({
    required this.profile,
    required this.onEditPressed,
    required this.onRequestDocumentsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          _buildInfoCards(context),
          const SizedBox(height: 24),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Hero(
            tag: 'profile_avatar',
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
              child: Text(
                profile.name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            profile.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            profile.email,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoTile(
                    icon: Icons.badge,
                    label: 'Student Number',
                    value: profile.studentNumber,
                    color: const Color(0xFF001184),
                  ),
                  const Divider(),
                  _InfoTile(
                    icon: Icons.school,
                    label: 'Strand', // Changed from Course
                    value: profile.strand, // Changed from course
                    color: const Color(0xFF001184),
                  ),
                  const Divider(),
                  _InfoTile(
                    icon: Icons.phone,
                    label: 'Contact',
                    value: profile.contact,
                    color: const Color(0xFF001184),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: onRequestDocumentsPressed,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 4,
              shadowColor: Theme.of(context).primaryColor.withOpacity(0.4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.description, size: 24),
                SizedBox(width: 12),
                Text(
                  'Request Documents',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Request History Button
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RequestHistoryScreen(),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Theme.of(context).primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Text(
                  'Request History',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Edit Profile Button
          OutlinedButton(
            onPressed: onEditPressed,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Theme.of(context).primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Logout Button
          TextButton(
            onPressed: () => _showLogoutDialog(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.logout, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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

void _showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: const Text('Logout'),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            }
          },
          child: const Text(
            'Logout',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorSection extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorSection({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlumniProfileScreen extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onEditPressed;

  const _AlumniProfileScreen({
    required this.profile,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // const SliverAppBar(
        //   expandedHeight: 150,
        //   pinned: true,
        //   flexibleSpace: FlexibleSpaceBar(
        //     title: Text('Alumni Profile'),
        //   ),
        // ),
        SliverToBoxAdapter(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAlumniHeader(context),
                const SizedBox(height: 24),
                _buildAlumniInfo(context),
                const SizedBox(height: 24),
                _buildActions(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlumniHeader(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
              child: Text(
                profile.name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              profile.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Class of ${profile.yearGraduated}',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlumniInfo(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _InfoTile(
              icon: Icons.email,
              label: 'Email',
              value: profile.email,
              color: const Color(0xFF001184),
            ),
            const Divider(),
            _InfoTile(
              icon: Icons.phone,
              label: 'Contact',
              value: profile.contact,
              color: const Color(0xFF001184),
            ),
            const Divider(),
            _InfoTile(
              icon: Icons.school,
              label: 'Year Graduated',
              value: profile.yearGraduated!,
              color: const Color(0xFF001184),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        OutlinedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RequestHistoryScreen(),
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                'Request History',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: onEditPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.edit),
              SizedBox(width: 8),
              Text('Edit Profile'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => _showLogoutDialog(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// class _QuickActionCard extends StatelessWidget {
//   final IconData icon;
//   final String title;
//   final VoidCallback onTap;

//   const _QuickActionCard({
//     required this.icon,
//     required this.title,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 10,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               icon,
//               size: 32,
//               color: const Color(0xFF001184),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               title,
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
