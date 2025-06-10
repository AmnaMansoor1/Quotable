import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_textfield.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
 
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
void initState() {
  super.initState();
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user == null) {
      print(' User is currently signed out!');
    } else {
      print(' User is signed in: ${user.email}');
    }
  });
}

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }


  Future<void> createUserWithEmailAndPassword() async {
    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );
      print("User created: ${userCredential.user?.uid}");

    } on FirebaseAuthException catch (e) {
          print("FirebaseAuthException: ${e.code} - ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CustomTextField(controller: emailController, hintText: "Email"),
            CustomTextField(
              controller: passwordController,
              hintText: "Password",
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: () async {
                await createUserWithEmailAndPassword();
              },
              child: const Text("Sign Up"),
            ),
          ],
        ),
      ),
    );
  }
}
