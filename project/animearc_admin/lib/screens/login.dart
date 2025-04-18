import 'package:animearc_admin/screens/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _showSetupAdmin = false;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkForAdmins();
  }

  Future<void> _checkForAdmins() async {
    try {
      final supabase = Supabase.instance.client;
      final admins = await supabase.from('tbl_admin').select('admin_id').limit(1);
      setState(() {
        _showSetupAdmin = admins.isEmpty;
      });
    } catch (e) {
      print('Error checking admins: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _setupFirstAdmin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_emailController.text.isEmpty || 
          _passwordController.text.isEmpty || 
          _nameController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Please fill in all fields';
          _isLoading = false;
        });
        return;
      }

      // Get Supabase client
      final supabase = Supabase.instance.client;
      
      // Create a new user
      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null) {
        // Add user to admin table
        await supabase.from('tbl_admin').insert({
          'admin_id': response.user!.id,
          'admin_name': _nameController.text.trim(),
          'admin_email': _emailController.text.trim(),
          
        });

        // Sign in with the new credentials
        await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Navigate to dashboard
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminHome(),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to create admin account';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter email and password';
          _isLoading = false;
        });
        return;
      }

      // Get Supabase client
      final supabase = Supabase.instance.client;
      
      // Sign in with email and password
      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Check if sign in was successful
      if (response.user != null) {
        final userId = response.user!.id;
        
        if (mounted) {
          try {
            // Check if the user is in the admin table by UUID
            final adminData = await supabase
                .from('tbl_admin')
                .select()
                .eq('admin_id', userId)
                .maybeSingle();

            if (adminData != null) {
              // Valid admin - Navigate to dashboard
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminHome(),
                  ),
                );
              }
            } else {
              // User exists but not an admin
              await supabase.auth.signOut();
              setState(() {
                _errorMessage = 'You are not authorized as an admin';
                _isLoading = false;
              });
            }
          } catch (e) {
            // Error checking admin status
            setState(() {
              _errorMessage = 'Error verifying admin status: ${e.toString()}';
              _isLoading = false;
            });
          }
        }
      } else {
        setState(() {
          _errorMessage = 'Invalid email or password';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/123.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF5D1E9E).withOpacity(0.8),
                const Color(0xFF1A0933).withOpacity(0.9),
              ],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: FadeInUp(
                duration: const Duration(milliseconds: 800),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 400,
                  ),
                  child: Card(
                    margin: const EdgeInsets.all(24),
                    color: Colors.black.withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo and Character
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF8A2BE2),
                                ),
                              ),
                              ClipOval(
                                child: Image.asset(
                                  "assets/123.png",
                                  width: 140,
                                  height: 140,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),

                          // Title with glowing effect
                          ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return LinearGradient(
                                colors: [
                                  Color(0xFFB975FF),
                                  Color(0xFF8A2BE2),
                                  Color(0xFFB975FF),
                                ],
                              ).createShader(bounds);
                            },
                            child: const Text(
                              'ANIME HUB',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Subtitle
                          Text(
                            _showSetupAdmin ? 'Create Admin Account' : 'Admin Portal',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[300],
                              letterSpacing: 1,
                            ),
                          ),
                          
                          const SizedBox(height: 32),

                          // Error message
                          if (_errorMessage.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(10),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Show Name field only in admin setup mode
                          if (_showSetupAdmin) ...[
                            TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                hintText: 'Admin Name',
                                prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF8A2BE2)),
                                hintStyle: TextStyle(color: Colors.grey[400]),
                              ),
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Email Field
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: 'Enter your email',
                              prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF8A2BE2)),
                              hintStyle: TextStyle(color: Colors.grey[400]),
                            ),
                            style: const TextStyle(color: Colors.white),
                          ),
                          
                          const SizedBox(height: 16),

                          // Password Field
                          TextField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              hintText: 'Your password',
                              prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF8A2BE2)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              hintStyle: TextStyle(color: Colors.grey[400]),
                            ),
                            style: const TextStyle(color: Colors.white),
                            onSubmitted: (_) => _showSetupAdmin ? _setupFirstAdmin() : _handleLogin(),
                          ),
                          
                          const SizedBox(height: 24),

                          // Login/Create Admin Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading 
                                ? null 
                                : (_showSetupAdmin ? _setupFirstAdmin : _handleLogin),
                              child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                  _showSetupAdmin ? 'Create Admin Account' : 'Login',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Forgot Password - only show in normal login
                          if (!_showSetupAdmin)
                            TextButton(
                              onPressed: () {
                                // Handle forgot password logic
                              },
                              child: Text(
                                'Forgot password?',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[300],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
