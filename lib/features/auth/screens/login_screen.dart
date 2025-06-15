import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_textfield.dart';
import '../../../widgets/app_logo.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> loginUserWithEmailAndPassword() async {
    if (!formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      String title = 'Login Failed';
      String message = 'An error occurred during login';
      
      switch (e.code) {
        case 'user-not-found':
          title = 'Account Not Found';
          message = 'No account found with this email address. Please check your email or sign up for a new account.';
          break;
        case 'wrong-password':
          title = 'Incorrect Password';
          message = 'The password you entered is incorrect. Please try again.';
          break;
        case 'invalid-email':
          title = 'Invalid Email';
          message = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          title = 'Account Disabled';
          message = 'This account has been disabled. Please contact support.';
          break;
        case 'too-many-requests':
          title = 'Too Many Attempts';
          message = 'Too many unsuccessful login attempts. Please try again later.';
          break;
        case 'invalid-credential':
          title = 'Invalid Credentials';
          message = 'The email or password you entered is incorrect. Please check and try again.';
          break;
        default:
          message = e.message ?? 'Login failed. Please try again.';
      }
      
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorModal(title, message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorModal('Unexpected Error', 'An unexpected error occurred. Please try again.');
      }
    }
  }

  void _showErrorModal(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.error_outline, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // App Logo
                const Center(
                  child: AppLogo(
                    size: 140,
                    showText: true,
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Login Form
                CustomTextField(
                  controller: emailController,
                  hintText: "Email",
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                CustomTextField(
                  controller: passwordController,
                  hintText: "Password",
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : loginUserWithEmailAndPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003B5C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text("Login", style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),
                
                // Sign Up Link
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    );
                  },
                  child: const Text(
                    "Don't have an account? Sign up",
                    style: TextStyle(color: Color(0xFF003B5C)),
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
