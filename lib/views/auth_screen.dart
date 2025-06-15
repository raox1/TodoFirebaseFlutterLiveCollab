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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Sign Up')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              Consumer<AuthViewModel>(
                builder: (context, authViewModel, child) {
                  if (authViewModel.isLoading) { // Add isLoading to AuthViewModel for better UX
                    return const CircularProgressIndicator();
                  }
                  return ElevatedButton(
                    onPressed: () => _submitAuthForm(context),
                    child: Text(_isLogin ? 'Login' : 'Sign Up'),
                  );
                },
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: Text(_isLogin ? 'Create an account' : 'I already have an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}