import 'package:findmybus/screens/ForgetPasswordScreen.dart';
import 'package:findmybus/screens/PassangerHomeScreen.dart';
import 'package:findmybus/screens/SignupScreen.dart';
import 'package:findmybus/screens/driverHomeScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  String selectedRole = "Passenger";
  String errorMessage = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  // Check if user is already logged in
  Future<void> _checkAutoLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedEmail = prefs.getString('user_email');
    String? savedRole = prefs.getString('user_role');
    String? savedUserId = prefs.getString('user_id');

    if (savedEmail != null && savedRole != null && savedUserId != null) {
      // User is already logged in, navigate to appropriate home screen
      if (mounted) {
        _navigateToHomeScreen(savedRole);
      }
    }
  }

  // Save user login info to SharedPreferences
  Future<void> _saveUserLoginInfo(
    String email,
    String role,
    String userId,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
    await prefs.setString('user_role', role);
    await prefs.setString('user_id', userId);
    await prefs.setBool('is_logged_in', true);
  }

  // Navigate to appropriate home screen based on role
  void _navigateToHomeScreen(String role) {
    if (role == "Driver") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DriverHomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PassangerHomeScreen()),
      );
    }
  }

  // Login function
  Future<void> _login(
    String email,
    String password,
    String selectedRole,
  ) async {
    setState(() {
      errorMessage = '';
      isLoading = true;
    });

    // Validate input
    if (email.trim().isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = 'Please enter both email and password';
        isLoading = false;
      });
      return;
    }

    try {
      // Sign in with Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email.trim(), password: password);

      // Get user data from Firestore to verify role
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();

      if (!userDoc.exists) {
        setState(() {
          errorMessage = 'User data not found. Please contact support.';
          isLoading = false;
        });
        return;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String actualRole = userData['role'] ?? '';

      // Check if selected role matches the user's actual role
      if (actualRole != selectedRole) {
        setState(() {
          errorMessage =
              'Invalid role selected. You are registered as a $actualRole.';
          isLoading = false;
        });
        return;
      }

      // Save login info to SharedPreferences
      await _saveUserLoginInfo(
        email.trim(),
        actualRole,
        userCredential.user!.uid,
      );

      setState(() {
        isLoading = false;
      });

      // Navigate to appropriate home screen
      if (mounted) {
        _navigateToHomeScreen(actualRole);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back, ${userData['name'] ?? 'User'}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = _getErrorMessage(e.code);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'An unexpected error occurred. Please try again.';
        isLoading = false;
      });
    }
  }

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      default:
        return 'Login failed. Please check your credentials.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Welcome to',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.normal),
                ),
                const Text(
                  'Find My Bus',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                // Role Selection Dropdown
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  onChanged:
                      isLoading
                          ? null
                          : (String? newValue) {
                            setState(() {
                              selectedRole = newValue!;
                              errorMessage =
                                  ''; // Clear error when role changes
                            });
                          },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: Colors.purple,
                    ),
                    labelText: 'Select Role',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  items:
                      <String>[
                        'Passenger',
                        'Driver',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 20),
                // Email Input
                TextField(
                  controller: emailController,
                  enabled: !isLoading,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email, color: Colors.amber),
                    labelText: 'Email Address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Password Input
                TextField(
                  controller: passwordController,
                  enabled: !isLoading,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock, color: Colors.green),
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Forget Password Button
                TextButton(
                  onPressed:
                      isLoading
                          ? null
                          : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Forgetpasswordscreen(),
                              ),
                            );
                          },
                  child: const Text(
                    'Forget Password?',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Sign In Button
                ElevatedButton(
                  onPressed:
                      isLoading
                          ? null
                          : () {
                            _login(
                              emailController.text,
                              passwordController.text,
                              selectedRole,
                            );
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 50,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child:
                      isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'Sign in',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                ),
                const SizedBox(height: 20),
                // Error Message Display
                if (errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 20),
                // Sign up Button
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('New user?'),
                      TextButton(
                        onPressed:
                            isLoading
                                ? null
                                : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Signupscreen(),
                                    ),
                                  );
                                },
                        child: const Text('Sign up'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
