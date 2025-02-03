import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:odrs/firebase_options.dart';
import 'package:odrs/presentation/screens/admin/a_home.dart';
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
        '/admin': (context) => AdminScreen(),
        '/user': (context) => UserProfileScreen(
              userRepository: UserRepository(),
            ),
        '/login': (context) => LoginScreen(),
        '/documentRequest': (context) => DocumentRequestScreen(),
      },
      home: LoginScreen(),
    );
  }
}
