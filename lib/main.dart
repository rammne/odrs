import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:odrs/firebase_options.dart';
import 'package:odrs/presentation/screens/admin/admin_layout.dart';
import 'package:odrs/presentation/screens/login/alumni_info_screen.dart';
import 'package:odrs/presentation/screens/login/login_screen.dart';
import 'package:odrs/presentation/screens/user/document_request.dart';
import 'package:odrs/presentation/screens/user/u_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/admin': (context) => AdminLayout(),
        '/user': (context) => UserProfileScreen(
              userRepository: UserRepository(),
            ),
        '/login': (context) => LoginScreen(),
        '/guestInfo': (context) => const AlumniInfoScreen(),
        '/documentRequest': (context) => DocumentRequestScreen(),
      },
      home: LoginScreen(),
    );
  }
}
