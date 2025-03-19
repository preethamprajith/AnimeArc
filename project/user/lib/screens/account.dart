import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/screens/complaint.dart';
import 'package:user/screens/login.dart';
import 'package:user/screens/my_order.dart';
import 'package:user/screens/order_details.dart';
import 'package:user/screens/privacy.dart';
import 'package:user/screens/profilesettings.dart';

class Account extends StatefulWidget {
  const Account({super.key});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  final supabase = Supabase.instance.client;
  String userName = "Loading...";
  String userEmail = "Loading...";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          userName = "Guest";
          userEmail = "Not logged in";
          isLoading = false;
        });
        return;
      }

      final response = await supabase
          .from('tbl_user')
          .select('user_name, user_email')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        setState(() {
          userName = response['user_name'] ?? "No Name";
          userEmail = response['user_email'] ?? "No Email";
          isLoading = false;
        });
      } else {
        setState(() {
          userName = "User Not Found";
          userEmail = "No Email";
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching user details: $e");
      setState(() {
        userName = "Error";
        userEmail = "Error fetching email";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Account", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications, color: Colors.white),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: Colors.white),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            Row(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white, size: 40),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail,
                      style: const TextStyle(color: Colors.orangeAccent, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Settings Options
            _buildSettingItem(Icons.person_outline, "Edit Profile", const Profilesettings()),
            _buildSettingItem(Icons.lock_outline, "Privacy & Security", const Security()),
            _buildSettingItem(Icons.help_outline, "Complaint & Feedback", const Complaint()),
            _buildSettingItem(Icons.help_outline, "BOOKINGS ", const OrdersPage()),
            _buildSettingItem(Icons.logout, "Log Out", const Login(), isLogout: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, Widget page, {bool isLogout = false}) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: isLogout ? Colors.redAccent : Colors.white),
        title: Text(title, style: TextStyle(color: isLogout ? Colors.redAccent : Colors.white)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => page));
        },
      ),
    );
  }
}
