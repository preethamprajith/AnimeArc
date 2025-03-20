import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  bool isLoading = false;

  Future<void> changePassword() async {
    try {
      setState(() => isLoading = true);

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        showSnackBar("User not logged in!", Colors.red);
        return;
      }

      final email = user.email;
      final response = await Supabase.instance.client
          .from('tbl_user')
          .select('user_password')
          .eq('user_email', email!)
          .single();

      String oldPasswordDb = response['user_password'];

      if (_oldPasswordController.text != oldPasswordDb) {
        showSnackBar("Old password is incorrect!", Colors.red);
        setState(() => isLoading = false);
        return;
      }

      if (_newPasswordController.text != _confirmPasswordController.text) {
        showSnackBar("New passwords do not match!", Colors.red);
        setState(() => isLoading = false);
        return;
      }

      if (_newPasswordController.text.length < 6) {
        showSnackBar("Password must be at least 6 characters!", Colors.red);
        setState(() => isLoading = false);
        return;
      }

      await Supabase.instance.client
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
    } finally {
      setState(() => isLoading = false);
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
        title: const Text("Change Password", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          children: [
            // Lock Icon
            const Icon(Icons.lock, color: Colors.orange, size: 100),
            const SizedBox(height: 30),

            // Form Fields
            _buildPasswordField(_oldPasswordController, "Old Password", _obscureOldPassword, () {
              setState(() => _obscureOldPassword = !_obscureOldPassword);
            }),
            const SizedBox(height: 15),
            _buildPasswordField(_newPasswordController, "New Password", _obscureNewPassword, () {
              setState(() => _obscureNewPassword = !_obscureNewPassword);
            }),
            const SizedBox(height: 15),
            _buildPasswordField(_confirmPasswordController, "Confirm New Password", _obscureConfirmPassword, () {
              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
            }),
            const SizedBox(height: 30),

            // Update Button
            ElevatedButton(
              onPressed: isLoading ? null : changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 50),
                elevation: 6,
                shadowColor: Colors.orangeAccent,
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.orange.withOpacity(0.6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.orange, width: 2),
          ),
          suffixIcon: IconButton(
            icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.white),
            onPressed: toggle,
          ),
        ),
      ),
    );
  }
}
