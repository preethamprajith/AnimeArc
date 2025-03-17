import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/main.dart';

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

  @override
  void initState() {
    super.initState();
    fetchUserData(); // Fetch current user data when screen loads
  }

  Future<void> fetchUserData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response = await supabase
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
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from('tbl_user').update({
        'user_name': _usernameController.text,
        'user_email': _useremailController.text,
        'user_address': _useraddressController.text,
        'user_contact': _usercontactController.text,
      }).eq('user_id', user.id);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Profile Updated Successfully!", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      print("ERROR UPDATING USER DATA: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Error updating profile!", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),

            _buildTextField(controller: _usernameController, label: "User Name"),
            const SizedBox(height: 20),

            _buildTextField(controller: _useremailController, label: "Email ID"),
            const SizedBox(height: 20),

            _buildTextField(controller: _useraddressController, label: "Address"),
            const SizedBox(height: 20),

            _buildTextField(controller: _usercontactController, label: "Contact Number"),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: updateUserData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size(double.infinity, 50),
                elevation: 5,
              ),
              child: const Text(
                "Update Profile",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label}) {
    return TextFormField(
      controller: controller,
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
