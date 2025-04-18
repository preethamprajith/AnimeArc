import 'package:flutter/material.dart';
import 'package:user/main.dart';
import 'package:user/screens/dashboard.dart';
import 'package:user/screens/register.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _orguseremailController = TextEditingController();
  final TextEditingController _orguserpassController = TextEditingController();

 Future<void> login() async {
  try {
    await supabase.auth.signInWithPassword(
      email: _orguseremailController.text,
      password: _orguserpassController.text,
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => Dashboard()),
    );
  } catch (e) {
    print("Error during login: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Login failed: ${e.toString()}")),
    );
  }
}


  bool _obscurePassword = true;

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
                  controller: _orguseremailController,
                  hintText: 'Enter your email',
                  obscureText: false,
                ),
                const SizedBox(height: 20),

                // Password Field
                _buildTextField(
                  pass: true,
                  controller: _orguserpassController,
                  hintText: 'Enter your password',
                  obscureText: _obscurePassword,
                  toggleObscure: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),

                const SizedBox(height: 20),

                // Login Button
                _buildElevatedButton(
                  label: "LOGIN",
                  onPressed: () {
                  login();
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
                        MaterialPageRoute(
                            builder: (context) => const RegisterPage()));
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

  Widget _buildTextField({
    bool pass = false,
    required String hintText,
    required bool obscureText,
    required TextEditingController controller,
    VoidCallback? toggleObscure,
  }) {
    return TextFormField(
      controller: controller,
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
        prefixIcon: hintText.toLowerCase().contains("password")
            ? const Icon(Icons.lock, color: Colors.white)
            : const Icon(Icons.email, color: Colors.white),
        suffixIcon: pass
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white,
                ),
                onPressed: toggleObscure,
              )
            : null,
      ),
    );
  }
}

Widget _buildElevatedButton(
    {required String label, required VoidCallback onPressed}) {
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
