import 'package:flutter/material.dart';
import 'package:user/main.dart';
import 'package:user/screens/login.dart';

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

  Future<void> register() async {
  try {
    final auth = await supabase.auth.signUp(
      email: _useremailController.text.trim(),
      password: _userpassController.text.trim(),
    );

    final uid = auth.user?.id;
    if (uid != null && uid.isNotEmpty) {
      insertuser(uid);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration successful!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration failed: No user ID returned")),
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
    } catch (e) {
      print("ERROR INSERTING DATA: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text(
          'Register',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 5,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with glow effect
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange.withOpacity(0.22),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: const Icon(
                    Icons.animation_rounded,
                    size: 60,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 20),

                // Welcome Text
                const Text(
                  "Welcome to Anime Arc!",
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Create an account to join the adventure.",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Username Field
                _buildTextField(controller: _usernameController, label: "User Name"),
                const SizedBox(height: 20),

                // Email Field
                _buildTextField(controller: _useremailController, label: "Email ID"),
                const SizedBox(height: 20),

                // Password Field
                _buildTextField(controller: _userpassController, label: "Password", obscureText: true),
                const SizedBox(height: 20),

                // Address Field
                _buildTextField(controller: _useraddressController, label: "Address"),
                const SizedBox(height: 20),

                // Contact Field
                _buildTextField(controller: _usercontactController, label: "Contact Number"),
                const SizedBox(height: 20),

                // Register Button
                ElevatedButton(
                  onPressed: () {
                    register();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                    shadowColor: Colors.orangeAccent,
                    elevation: 12,
                  ),
                  child: const Text(
                    "Register",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Back to Login Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const Login()),
                    );
                  },
                  child: const Text(
                    "Back to Login",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, bool obscureText = false}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        border: const OutlineInputBorder(),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.orange),
        ),
      ),
    );
  }
}
