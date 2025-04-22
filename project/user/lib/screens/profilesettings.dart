import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Profilesettings extends StatefulWidget {
  const Profilesettings({super.key});

  @override
  State<Profilesettings> createState() => _ProfilesettingsState();
}

class _ProfilesettingsState extends State<Profilesettings> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _useremailController = TextEditingController();
  final TextEditingController _useraddressController = TextEditingController();
  final TextEditingController _usercontactController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchUserData(); // Fetch current user data when screen loads
  }

  // Update the fetchUserData method
  Future<void> fetchUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('tbl_user')
            .select()
            .eq('user_id', user.id)
            .single();

        setState(() {
          _usernameController.text = response['user_name']?.toString() ?? "";
          _useremailController.text = response['user_email']?.toString() ?? "";
          _useraddressController.text = response['user_address']?.toString() ?? "";
          _usercontactController.text = response['user_contact']?.toString() ?? "";
        });
      }
    } catch (e) {
      print("ERROR FETCHING USER DATA: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Error loading profile data!", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ));
    }
  }

  // Update the updateUserData method to handle contact as number
  Future<void> updateUserData() async {
    try {
      setState(() => isLoading = true);

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Validate contact number
      int? contact;
      try {
        contact = int.parse(_usercontactController.text.replaceAll(RegExp(r'[^0-9]'), ''));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please enter a valid contact number!", 
            style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.orange,
        ));
        setState(() => isLoading = false);
        return;
      }

      await Supabase.instance.client.from('tbl_user').update({
        'user_name': _usernameController.text.trim(),
        'user_email': _useremailController.text.trim(),
        'user_address': _useraddressController.text.trim(),
        'user_contact': contact, // Store as integer
      }).eq('user_id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Profile Updated Successfully!", 
            style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      print("ERROR UPDATING USER DATA: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Error updating profile!", 
            style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A1A70),
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1,
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
              // Enhanced Profile Picture Section
              Center(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange,
                            const Color(0xFF4A1A70),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white10,
                        child: Icon(Icons.person, size: 60, color: Colors.white),
                      ),
                    ),
                  
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Profile Info Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  children: [
                    _buildEnhancedTextField(
                      controller: _usernameController,
                      label: "Username",
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 20),
                    _buildEnhancedTextField(
                      controller: _useremailController,
                      label: "Email",
                      icon: Icons.email_outlined,
                      isEmail: true,
                    ),
                    const SizedBox(height: 20),
                    _buildEnhancedTextField(
                      controller: _useraddressController,
                      label: "Address",
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 20),
                    _buildEnhancedTextField(
                      controller: _usercontactController,
                      label: "Contact",
                      icon: Icons.phone_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Enhanced Update Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange,
                      const Color(0xFF4A1A70),
                    ],
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
                  onPressed: isLoading ? null : updateUserData,
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
                            Icon(Icons.save_outlined, color: Colors.white),
                            SizedBox(width: 12),
                            Text(
                              "Save Changes",
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

  // Update the _buildEnhancedTextField method to add contact validation
  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isEmail = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4A1A70).withOpacity(0.3),
        ),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        keyboardType: label == "Contact" 
            ? TextInputType.phone
            : isEmail 
                ? TextInputType.emailAddress 
                : TextInputType.text,
        maxLength: label == "Contact" ? 10 : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(icon, color: Colors.orange),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          counterText: "", // Hide character counter
        ),
        onChanged: (value) {
          if (label == "Contact") {
            // Only allow numbers
            final newValue = value.replaceAll(RegExp(r'[^0-9]'), '');
            if (newValue != value) {
              controller.text = newValue;
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: newValue.length),
              );
            }
          }
        },
      ),
    );
  }
}
