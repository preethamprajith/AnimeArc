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
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A1A70),
        title: const Text(
          "Security Settings",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF4A1A70).withOpacity(0.8),
              const Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Column(
            children: [
              // Animated Lock Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange.withOpacity(0.1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock,
                  color: Colors.orange,
                  size: 60,
                ),
              ),
              const SizedBox(height: 40),

              // Security Message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.security, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Keep your account secure with a strong password",
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Password Fields
              _buildPasswordField(
                _oldPasswordController,
                "Current Password",
                _obscureOldPassword,
                () => setState(() => _obscureOldPassword = !_obscureOldPassword),
                Icons.lock_outline,
              ),
              const SizedBox(height: 20),
              _buildPasswordField(
                _newPasswordController,
                "New Password",
                _obscureNewPassword,
                () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                Icons.lock_clock,
              ),
              const SizedBox(height: 20),
              _buildPasswordField(
                _confirmPasswordController,
                "Confirm New Password",
                _obscureConfirmPassword,
                () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                Icons.lock_person,
              ),
              const SizedBox(height: 40),

              // Update Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A1A70), Colors.deepPurple],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A1A70).withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: isLoading ? null : changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_reset, color: Colors.white),
                            SizedBox(width: 12),
                            Text(
                              "Update Password",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    String label,
    bool obscureText,
    VoidCallback toggle,
    IconData prefixIcon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4A1A70).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A1A70).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(prefixIcon, color: const Color(0xFF4A1A70)),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF4A1A70),
            ),
            onPressed: toggle,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        ),
      ),
    );
  }
}
