import 'package:animearc_admin/screens/dashboard.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const AdminLoginApp());
}

class AdminLoginApp extends StatelessWidget {
  const AdminLoginApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Admin Login',
      theme: ThemeData(
        primaryColor: const Color(0xFFFFA500), // Orange theme
        fontFamily: 'Roboto',
      ),
      home: const AdminLoginPage(),
    );
  }
}

class AdminLoginPage extends StatelessWidget {
  const AdminLoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF000000), // Black background
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 400, // Fixed width for the login form
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor:
                        Color(0xFF4D403F), // Dark brown background for the logo
                    child: Icon(
                      Icons.animation_outlined,
                      color: Color(0xFFFFA500), // Orange logo color
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  const Text(
                    'ANIME ARC',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFA500), // Orange text color
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email Field
                  Card(
                    elevation: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Enter your email',
                        filled: true,
                        fillColor:
                            Colors.grey[850], // Dark grey input background
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  Card(
                    elevation: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Your password',
                        filled: true,
                        fillColor:
                            Colors.grey[850], // Dark grey input background
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                         Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Dashboard()),
                    );
                        // Handle login logic
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFFFA500), // Orange button color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'LOGIN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black, // Black text on orange button
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Forgot Password
                  TextButton(
                    onPressed: () {
                      // Handle forgot password logic
                    },
                    child: const Text(
                      'Forgot your password?',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
