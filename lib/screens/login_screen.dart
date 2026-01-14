import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import 'menu_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Call auth service
        final result = await _authService.login(
          _usernameEmailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        if (result['success']) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login successful!'),
              backgroundColor: Color(0xFF547792),
              duration: Duration(seconds: 2),
            ),
          );

          // Navigate to menu screen and remove all previous routes
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MenuScreen()),
                (route) => false,
          );
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Login failed'),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    final isTablet = size.width >= 600;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF213448), // Dark Blue
              Color(0xFF547792), // Teal
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 48.0 : (isSmallScreen ? 20.0 : 24.0),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTablet ? 500 : double.infinity,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Icon
                      Container(
                        width: isSmallScreen ? 80 : 100,
                        height: isSmallScreen ? 80 : 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAE0CF).withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.inventory_2_rounded,
                          size: isSmallScreen ? 50 : 60,
                          color: const Color(0xFFEAE0CF),
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 20 : 24),

                      // Title
                      Text(
                        'Inventory Manager',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 26 : (isTablet ? 36 : 32),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFEAE0CF),
                          letterSpacing: 0.5,
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 6 : 8),

                      // Subtitle
                      Text(
                        'Your Stock, Simplified',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          color: const Color(0xFFEAE0CF).withOpacity(0.9),
                          letterSpacing: 0.3,
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 36 : 48),

                      // Login Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAE0CF),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(
                            isSmallScreen ? 24.0 : (isTablet ? 40.0 : 32.0),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Form Title
                                Text(
                                  'Welcome Back',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 20 : 24,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF213448),
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                SizedBox(height: isSmallScreen ? 20 : 24),

                                // Username/Email TextField
                                TextFormField(
                                  controller: _usernameEmailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(
                                    color: const Color(0xFF213448),
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Username / Email',
                                    labelStyle: TextStyle(
                                      color: const Color(0xFF547792),
                                      fontSize: isSmallScreen ? 13 : 15,
                                    ),
                                    hintText: 'Enter your username or email',
                                    hintStyle: TextStyle(
                                      color: const Color(0xFF547792).withOpacity(0.5),
                                      fontSize: isSmallScreen ? 13 : 15,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.person_outline,
                                      color: const Color(0xFF547792),
                                      size: isSmallScreen ? 20 : 24,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF94B4C1),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF213448),
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.red.shade700,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 12 : 16,
                                      vertical: isSmallScreen ? 14 : 16,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your username or email';
                                    }
                                    return null;
                                  },
                                ),

                                SizedBox(height: isSmallScreen ? 14 : 16),

                                // Password TextField
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: !_isPasswordVisible,
                                  style: TextStyle(
                                    color: const Color(0xFF213448),
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle: TextStyle(
                                      color: const Color(0xFF547792),
                                      fontSize: isSmallScreen ? 13 : 15,
                                    ),
                                    hintText: 'Enter your password',
                                    hintStyle: TextStyle(
                                      color: const Color(0xFF547792).withOpacity(0.5),
                                      fontSize: isSmallScreen ? 13 : 15,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: const Color(0xFF547792),
                                      size: isSmallScreen ? 20 : 24,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: const Color(0xFF547792),
                                        size: isSmallScreen ? 20 : 24,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible = !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF94B4C1),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF213448),
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.red.shade700,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 12 : 16,
                                      vertical: isSmallScreen ? 14 : 16,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),

                                SizedBox(height: isSmallScreen ? 6 : 8),

                                // Forgot Password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please contact your administrator to reset your password'),
                                          backgroundColor: Color(0xFF547792),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: const Color(0xFF213448),
                                        fontSize: isSmallScreen ? 12 : 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: isSmallScreen ? 12 : 16),

                                // Login Button
                                SizedBox(
                                  height: isSmallScreen ? 50 : 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF213448),
                                      foregroundColor: const Color(0xFFEAE0CF),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                      disabledBackgroundColor:
                                      const Color(0xFF213448).withOpacity(0.6),
                                    ),
                                    child: _isLoading
                                        ? SizedBox(
                                      width: isSmallScreen ? 20 : 24,
                                      height: isSmallScreen ? 20 : 24,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                            Color(0xFFEAE0CF)),
                                      ),
                                    )
                                        : Text(
                                      'LOGIN',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 14 : 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 20 : 24),

                      // Test Credentials Helper (Remove in production)
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAE0CF).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFEAE0CF).withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Test Credentials',
                              style: TextStyle(
                                color: const Color(0xFFEAE0CF),
                                fontSize: isSmallScreen ? 12 : 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 6 : 8),
                            Text(
                              'Admin: admin / admin123\nUser: user / user123',
                              style: TextStyle(
                                color: const Color(0xFFEAE0CF).withOpacity(0.9),
                                fontSize: isSmallScreen ? 11 : 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 12 : 16),

                      // Company Info Footer
                      Text(
                        '© 2026 Company Name. All rights reserved.',
                        style: TextStyle(
                          color: const Color(0xFFEAE0CF).withOpacity(0.7),
                          fontSize: isSmallScreen ? 10 : 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
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