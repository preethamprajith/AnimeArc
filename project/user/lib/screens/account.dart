import 'package:flutter/material.dart';
import 'package:user/screens/complaint.dart';
import 'package:user/screens/login.dart';
import 'package:user/screens/privacy.dart';
import 'package:user/screens/profilesettings.dart';

class Account extends StatefulWidget {
  const Account({super.key});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
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
                  children: const [
                    Text(
                      "Username",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Free Member",
                      style: TextStyle(color: Colors.orangeAccent, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Settings Options
            _buildSettingItem(Icons.person_outline, " edit Profile ", Profilesettings()),
            _buildSettingItem(Icons.lock_outline, "Privacy & Security",Security()),
            
            _buildSettingItem(Icons.help_outline, "complaint and feedback", Complaint()),
            _buildSettingItem(Icons.logout, "Log Out", isLogout: true, Login()),
            
     
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
           Navigator.push(context, MaterialPageRoute(builder: (context) => page,));
        },
      ),
    );
  }
}
