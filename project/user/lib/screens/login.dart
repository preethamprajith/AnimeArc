import 'package:flutter/material.dart';
import 'package:user/main.dart';
import 'package:user/screens/dashboard.dart';
import 'package:user/screens/register.dart';
import 'package:google_fonts/google_fonts.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _orguseremailController = TextEditingController();
  final TextEditingController _orguserpassController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await supabase.auth.signInWithPassword(
        email: _orguseremailController.text.trim(),
        password: _orguserpassController.text,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Dashboard()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Login failed: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D0A4D), // Dark purple background
      body: Stack(
        children: [
          // Background image with gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF4A1A70), // Rich purple top
                  Color(0xFF2D0A4D), // Darker purple bottom
                ],
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Anime character in circle
                      _buildAnimeHeader(),
                      const SizedBox(height: 15),
                      
                      // Stylized app name
                      _buildStylizedAppName(),
                      const SizedBox(height: 10),
                      
                      // Tagline
                      Text(
                        "Your ultimate anime streaming experience",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Email Field
                      _buildTextField(
                        controller: _orguseremailController,
                        hintText: 'Email',
                        obscureText: false,
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      _buildTextField(
                        pass: true,
                        controller: _orguserpassController,
                        hintText: 'Password',
                        obscureText: _obscurePassword,
                        toggleObscure: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        
                        
                      ),
                      
                      const SizedBox(height: 25),

                      // Login Button
                      _buildGradientButton(
                        label: "Login",
                        onPressed: login,
                      ),

                      const SizedBox(height: 20),
                      
                      // Register prompt
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RegisterPage()),
                              );
                            },
                            child: Text(
                              "Register",
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFE991FF),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Footer text
                      
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimeHeader() {
    return Container(
      height: 180,
      width: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFBF55EC).withOpacity(0.3),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
        image: const DecorationImage(
          image: AssetImage('assets/123.png'),  // Updated path
          fit: BoxFit.cover,
          // Removed errorBuilder as it is not supported by DecorationImage
        ),
      ),
    );
  }
  
  Widget _buildStylizedAppName() {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: "anime",
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          TextSpan(
            text: "Hub",
            style: GoogleFonts.montserrat(
              color: const Color(0xFFE991FF),
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ],
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE991FF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 14,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your ${hintText.toLowerCase()}';
          }
          if (hintText.toLowerCase() == 'email') {
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(value)) {
              return 'Please enter a valid email';
            }
          }
          if (hintText.toLowerCase() == 'password') {
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
            color: Colors.white60,
            fontSize: 14,
          ),
          errorStyle: GoogleFonts.poppins(
            color: Colors.red[300],
            fontSize: 12,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          border: InputBorder.none,
          prefixIcon: hintText.toLowerCase().contains("password")
              ? const Icon(Icons.lock_outline, color: Colors.white70, size: 20)
              : const Icon(Icons.email_outlined, color: Colors.white70, size: 20),
          suffixIcon: pass
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white70,
                    size: 20,
                  ),
                  onPressed: toggleObscure,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFFE991FF), Color(0xFFBF55EC)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBF55EC).withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 1,
          ),
        ],
      ),
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}