import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_textfield.dart';
import '../../../widgets/app_logo.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> createUserWithEmailAndPassword() async {
    if (!formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        // Show success modal
        _showSuccessModal();
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      
      String title = 'Sign Up Failed';
      String message = 'An error occurred during sign up';
      
      switch (e.code) {
        case 'weak-password':
          title = 'Weak Password';
          message = 'Password should be at least 6 characters long. Please choose a stronger password.';
          break;
        case 'email-already-in-use':
          title = 'Email Already Exists';
          message = 'An account already exists with this email address. Please try logging in instead.';
          break;
        case 'invalid-email':
          title = 'Invalid Email';
          message = 'Please enter a valid email address.';
          break;
        case 'operation-not-allowed':
          title = 'Sign Up Disabled';
          message = 'Email/password accounts are not enabled. Please contact support.';
          break;
        case 'too-many-requests':
          title = 'Too Many Attempts';
          message = 'Too many unsuccessful attempts. Please try again later.';
          break;
        default:
          message = e.message ?? 'Sign up failed. Please try again.';
      }
      
      if (mounted) {
        _showErrorModal(title, message);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (mounted) {
        _showErrorModal('Unexpected Error', 'An unexpected error occurred. Please try again.');
      }
    }
  }

  void _showSuccessModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Success!',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your account has been created successfully!',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'You can now log in with your credentials.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to login screen
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Go to Login'),
            ),
          ],
        );
      },
    );
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
      appBar: AppBar(
        title: const Text("Create Account"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // App Logo (smaller for signup)
                const Center(
                  child: AppLogo(
                    size: 100,
                    showText: true,
                  ),
                ),
                
                const SizedBox(height: 32),
                
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
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    if (!RegExp(r'^(?=.*[a-zA-Z])').hasMatch(value)) {
                      return 'Password must contain at least one letter';
                    }
                    return null;
                  },
                ),
                CustomTextField(
                  controller: confirmPasswordController,
                  hintText: "Confirm Password",
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != passwordController.text) {
                      return 'Passwords do not match';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : createUserWithEmailAndPassword,
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
                      : const Text("Sign Up", style: TextStyle(fontSize: 16)),
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
