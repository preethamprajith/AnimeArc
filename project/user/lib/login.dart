import 'package:flutter/material.dart';
import 'package:user/register.dart';

class InvictusLogin extends StatefulWidget {
  const InvictusLogin({super.key});

  @override
  State<InvictusLogin> createState() => _InvictusLoginState();
}

class _InvictusLoginState extends State<InvictusLogin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with glow effect
                _buildLogo(),
                const SizedBox(height: 20),

                // App Name
                const Text(
                  "ANIME ARC",
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),

                // Email Field
                _buildTextField(
                  hintText: 'Enter your email',
                  obscureText: false,
                ),
                const SizedBox(height: 20),

                // Password Field
                _buildTextField(
                  hintText: 'Your password',
                  obscureText: true,
                ),
                const SizedBox(height: 20),

                // Login Button
                _buildElevatedButton(
                  label: "LOGIN",
                  onPressed: () {
                    // Handle login logic
                  },
                ),
                const SizedBox(height: 10),

                // Forgot Password
                TextButton(
                  onPressed: () {
                    // Handle forgot password logic
                  },
                  child: const Text(
                    "Forgot your password?",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 20),

                // Register Now Button
                _buildElevatedButton(
                  label: "Register now",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterPage()),
                    );
                  },
                ),
                const SizedBox(height: 20),

               
                
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.orange.withOpacity(0.22),
      ),
      padding: const EdgeInsets.all(20),
      child: const Icon(
        Icons.animation_outlined,
        size: 60,
        color: Colors.orange,
      ),
    );
  }

  Widget _buildTextField({required String hintText, required bool obscureText}) {
    return TextField(
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[850],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildElevatedButton({required String label, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        minimumSize: const Size(double.infinity, 50),
        shadowColor: Colors.orangeAccent,
        elevation: 10,
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }


 
}
