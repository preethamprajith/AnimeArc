import 'package:flutter/material.dart';
import 'package:user/main.dart';
import 'package:user/screens/login.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _useremailController = TextEditingController();
  final TextEditingController _userpassController = TextEditingController();
  final TextEditingController _useraddressController = TextEditingController();
  final TextEditingController _usercontactController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      if (_userpassController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Passwords don't match")),
        );
        return;
      }
      
      final auth = await supabase.auth.signUp(
        email: _useremailController.text.trim(),
        password: _userpassController.text.trim(),
      );

      final uid = auth.user?.id;
      if (uid != null && uid.isNotEmpty) {
        insertuser(uid);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration successful!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration failed: No user ID returned")),
        );
      }
    } catch (e) {
      print("AUTH ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration error: ${e.toString()}")),
      );
    }
  }

  Future<void> insertuser(final id) async {
    try {
      String name = _usernameController.text;
      String email = _useremailController.text;
      String password = _userpassController.text;
      String address = _useraddressController.text;
      String contact = _usercontactController.text;

      await supabase.from('tbl_user').insert({
        'user_id': id,
        'user_name': name,
        'user_email': email,
        'user_password': password,
        'user_address': address,
        'user_contact': contact,
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          "User Registered Successfully!",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ));

      _usernameController.clear();
      _useremailController.clear();
      _userpassController.clear();
      _useraddressController.clear();
      _usercontactController.clear();
      _confirmPasswordController.clear();
      
      // Navigate back to login
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const Login())
      );
    } catch (e) {
      print("ERROR INSERTING DATA: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D0A4D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background gradient
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
          // Content overlay with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.purple.withOpacity(0.7),
                  const Color(0xFF2D0A4D).withOpacity(0.9),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Header with anime character
                        _buildAnimeHeader(),
                        const SizedBox(height: 20),
        
                        // Stylized app name
                        _buildStylizedAppName(),
                        const SizedBox(height: 10),
                        
                        // Tagline
                        Text(
                          "Create your account to start streaming",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Form fields
                        _buildInputField(
                          controller: _usernameController,
                          hintText: "Username",
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 15),
                        
                        _buildInputField(
                          controller: _useremailController,
                          hintText: "Email",
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 15),
                        
                        _buildInputField(
                          controller: _userpassController,
                          hintText: "Password",
                          icon: Icons.lock_outline,
                          isPassword: true,
                        ),
                        const SizedBox(height: 15),
                        
                        _buildInputField(
                          controller: _confirmPasswordController,
                          hintText: "Confirm Password",
                          icon: Icons.lock_outline,
                          isPassword: true,
                        ),
                        const SizedBox(height: 15),
                        
                        _buildInputField(
                          controller: _useraddressController,
                          hintText: "Address",
                          icon: Icons.home_outlined,
                        ),
                        const SizedBox(height: 15),
                        
                        _buildInputField(
                          controller: _usercontactController,
                          hintText: "Phone Number",
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 30),
        
                        // Register Button
                        _buildGradientButton(
                          label: "Register",
                          onPressed: register,
                        ),
                        const SizedBox(height: 25),
        
                        // Back to Login Text
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Already have an account? ",
                              style: TextStyle(color: Colors.white70),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const Login()),
                                );
                              },
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                  color: Color(0xFFE991FF),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
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
      height: 150,
      width: 150,
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
              fontSize: 28,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          TextSpan(
            text: "Hub",
            style: GoogleFonts.montserrat(
              color: const Color(0xFFE991FF),
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
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
        obscureText: isPassword && 
          ((hintText == "Password" && !_isPasswordVisible) || 
           (hintText == "Confirm Password" && !_isConfirmPasswordVisible)),
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 14,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $hintText';
          }
          if (hintText == "Email") {
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(value)) {
              return 'Please enter a valid email';
            }
          }
          if (hintText == "Password") {
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
          }
          if (hintText == "Confirm Password") {
            if (value != _userpassController.text) {
              return 'Passwords do not match';
            }
          }
          if (hintText == "Phone Number") {
            final phoneRegex = RegExp(r'^\+?[\d\s-]{10,}$');
            if (!phoneRegex.hasMatch(value)) {
              return 'Please enter a valid phone number';
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Colors.white70, size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    (hintText == "Password" ? _isPasswordVisible : _isConfirmPasswordVisible)
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.white70,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      if (hintText == "Password") {
                        _isPasswordVisible = !_isPasswordVisible;
                      } else {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      }
                    });
                  },
                )
              : null,
          errorStyle: GoogleFonts.poppins(
            color: Colors.red[300],
            fontSize: 12,
          ),
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
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          colors: [Color(0xFFE991FF), Color(0xFFB829FB)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB829FB).withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}