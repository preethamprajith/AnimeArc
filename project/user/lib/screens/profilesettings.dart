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
          _usernameController.text = response['user_name'] ?? "";
          _useremailController.text = response['user_email'] ?? "";
          _useraddressController.text = response['user_address'] ?? "";
          _usercontactController.text = response['user_contact'] ?? "";
        });
      }
    } catch (e) {
      print("ERROR FETCHING USER DATA: $e");
    }
  }

  Future<void> updateUserData() async {
    try {
      setState(() => isLoading = true);

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('tbl_user').update({
        'user_name': _usernameController.text,
        'user_email': _useremailController.text,
        'user_address': _useraddressController.text,
        'user_contact': _usercontactController.text,
      }).eq('user_id', user.id);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Profile Updated Successfully!", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ));

      setState(() => isLoading = false);
    } catch (e) {
      print("ERROR UPDATING USER DATA: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Error updating profile!", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ));
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Color(0xFF4A1A70),
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          children: [
            // Profile Picture Section
            Center(
              child: Stack(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFF4A1A70),
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF4A1A70),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        onPressed: () {
                          // Implement Profile Picture Upload
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Form Fields
            _buildTextField(controller: _usernameController, label: "User Name"),
            const SizedBox(height: 15),
            _buildTextField(controller: _useremailController, label: "Email ID", isEmail: true),
            const SizedBox(height: 15),
            _buildTextField(controller: _useraddressController, label: "Address"),
            const SizedBox(height: 15),
            _buildTextField(controller: _usercontactController, label: "Contact Number"),
            const SizedBox(height: 30),

            // Update Button
            ElevatedButton(
              onPressed: isLoading ? null : updateUserData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4A1A70),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 50),
                elevation: 6,
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Update Profile",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, bool isEmail = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF4A1A70),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Color(0xFF4A1A70),),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF4A1A70), width: 2),
          ),
        ),
      ),
    );
  }
}
