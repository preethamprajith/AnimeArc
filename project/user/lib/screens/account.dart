import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/screens/complaint.dart';
import 'package:user/screens/login.dart';
import 'package:user/screens/my_order.dart';
import 'package:user/screens/privacy.dart';
import 'package:user/screens/profilesettings.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user/components/anime_button.dart';
import 'package:user/theme/anime_theme.dart';

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Profile",
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
         
        ],
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AnimeTheme.primaryPurple, // Rich purple
                  AnimeTheme.darkPurple,    // Darker purple
                ],
              ),
            ),
          ),
          
          // Content
          isLoading
              ? const Center(child: CircularProgressIndicator(color: AnimeTheme.accentPink))
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Section
                        _buildProfileCard(),
                        
                        const SizedBox(height: 24),
                        
                        // Section title
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
                          child: Text(
                            "Settings",
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        
                        // Settings Options
                        _buildSettingItem(
                          Icons.lock_outline, 
                          "Privacy & Security", 
                          const Security(),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        
                        _buildSettingItem(
                          Icons.feedback_outlined, 
                          "Complaint & Feedback", 
                          const Complaint(),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF16A085), Color(0xFF1ABC9C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        
                        _buildSettingItem(
                          Icons.shopping_bag_outlined, 
                          "My Orders", 
                          const OrdersPage(),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE67E22), Color(0xFFD35400)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Logout Button
                        Center(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: AnimeButton(
                              label: "Log Out",
                              isOutlined: true, 
                              icon: Icons.logout,
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context, 
                                  MaterialPageRoute(builder: (context) => const Login())
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  // Update the _buildProfileCard method
  Widget _buildProfileCard() {
    return AnimatedContainer(
      duration: AnimeTheme.defaultDuration,
      curve: AnimeTheme.defaultCurve,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AnimeTheme.profileGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AnimeTheme.accentPink.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Enhanced Avatar with Glow Effect
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AnimeTheme.accentPink.withOpacity(0.3),
                  blurRadius: 25,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Animated background glow
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.5, end: 1.0),
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AnimeTheme.accentPink.withOpacity(0.5 * value),
                            AnimeTheme.brightPurple.withOpacity(0.2 * value),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Avatar
                Hero(
                  tag: 'profile-avatar',
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: AnimeTheme.primaryPurple,
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: AnimeTheme.accentPink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Enhanced Username with Gradient
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.white, AnimeTheme.accentPink],
            ).createShader(bounds),
            child: Text(
              userName,
              style: GoogleFonts.montserrat(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Enhanced Email Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.email,
                  size: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
                const SizedBox(width: 8),
                Text(
                  userEmail,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Enhanced Edit Profile Button
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: AnimeTheme.accentGradient,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: AnimeTheme.accentPink.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Profilesettings()),
                  );
                },
                borderRadius: BorderRadius.circular(25),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Edit Profile",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, Widget page, {required Gradient gradient}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
        ),
      ),
    );
  }
}
