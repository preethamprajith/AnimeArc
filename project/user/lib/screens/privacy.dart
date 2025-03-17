import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/main.dart';

class Security extends StatefulWidget {
  const Security({super.key});

  @override
  State<Security> createState() => _SecurityState();
}

class _SecurityState extends State<Security> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> changePassword() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        showSnackBar("User not logged in!", Colors.red);
        return;
      }

      final email = user.email;
      final response = await supabase
          .from('tbl_user')
          .select('user_password')
          .eq('user_email', email!)
          .single();

      String oldPasswordDb = response['user_password'];

      if (_oldPasswordController.text != oldPasswordDb) {
        showSnackBar("Old password is incorrect!", Colors.red);
        return;
      }

      if (_newPasswordController.text != _confirmPasswordController.text) {
        showSnackBar("New passwords do not match!", Colors.red);
        return;
      }

      if (_newPasswordController.text.length < 6) {
        showSnackBar("Password must be at least 6 characters!", Colors.red);
        return;
      }

      await supabase
          .from('tbl_user')
          .update({'user_password': _newPasswordController.text})
          .eq('user_email', email);

      showSnackBar("Password updated successfully!", Colors.green);
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } catch (e) {
      print("ERROR UPDATING PASSWORD: $e");
      showSnackBar("Error updating password!", Colors.red);
    }
  }

  void showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text("Change Password", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildPasswordField(_oldPasswordController, "Old Password", _obscureOldPassword, () {
              setState(() => _obscureOldPassword = !_obscureOldPassword);
            }),
            const SizedBox(height: 20),
            _buildPasswordField(_newPasswordController, "New Password", _obscureNewPassword, () {
              setState(() => _obscureNewPassword = !_obscureNewPassword);
            }),
            const SizedBox(height: 20),
            _buildPasswordField(_confirmPasswordController, "Confirm New Password", _obscureConfirmPassword, () {
              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
            }),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size(double.infinity, 50),
                elevation: 5,
              ),
              child: const Text(
                "Update Password",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label, bool obscureText, VoidCallback toggle) {
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
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.white),
          onPressed: toggle,
        ),
      ),
    );
  }
}
