import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:your_task_app/viewmodels/auth_viewmodel.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitAuthForm(BuildContext context) async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@') || password.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email and password (at least 6 characters).')),
      );
      return;
    }

    if (_isLogin) {
      await authViewModel.signIn(email, password);
    } else {
      await authViewModel.signUp(email, password);
    }

    if (authViewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authViewModel.errorMessage!)),
      );
      // Clear error message after showing it
      authViewModel.clearErrorMessage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background for the entire screen
      appBar: AppBar(
        title: Text(
          _isLogin ? 'Welcome Back!' : 'Join Us!', // More engaging titles
          style: const TextStyle(
            color: Colors.black87, // Darker text for app bar title
            fontWeight: FontWeight.bold,
            fontSize: 24, // Slightly larger title
          ),
        ),
        backgroundColor: Colors.white, // White app bar background
        elevation: 0, // Remove app bar shadow
        centerTitle: true, // Center the title
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[200], // Subtle bottom border
            height: 1.0,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0), // Increased padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch children horizontally
            children: [
              // Optional: Add an icon or logo here
              Icon(
                _isLogin ? Icons.lock_open : Icons.person_add,
                size: 100,
                color: Colors.deepOrange, // Consistent accent color
              ),
              const SizedBox(height: 30),
              Text(
                _isLogin ? 'Login to your account' : 'Create a new account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address', // More descriptive label
                  hintText: 'your.email@example.com',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.email, color: Colors.grey[500]), // Icon inside TextField
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.deepOrange, width: 2), // Accent color on focus
                  ),
                  filled: true, // Fill the background of the text field
                  fillColor: Colors.grey[50], // Light grey fill
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
              ),
              const SizedBox(height: 16), // Increased spacing
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'at least 6 characters',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.lock, color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 30), // Increased spacing
              Consumer<AuthViewModel>(
                builder: (context, authViewModel, child) {
                  if (authViewModel.isLoading) {
                    return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange)));
                  }
                  return SizedBox(
                    height: 50, // Fixed height for the button
                    child: ElevatedButton(
                      onPressed: () => _submitAuthForm(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange, // Vibrant button color
                        foregroundColor: Colors.white, // White text
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // Rounded button
                        ),
                        elevation: 4, // Button shadow
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: Text(_isLogin ? 'Login' : 'Sign Up'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20), // Spacing
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                    // Clear controllers when switching form
                    _emailController.clear();
                    _passwordController.clear();
                    // Clear any previous error message
                    Provider.of<AuthViewModel>(context, listen: false).clearErrorMessage();
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.deepOrange, // Accent color for text button
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(_isLogin ? 'Create an account' : 'I already have an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}