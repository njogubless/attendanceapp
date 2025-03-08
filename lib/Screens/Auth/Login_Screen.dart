import 'package:attendanceapp/Providers/auth_providers.dart';
import 'package:attendanceapp/Screens/admin/admin_dashboard';
import 'package:attendanceapp/Screens/lecturer/lecturer_dashboard.dart';
import 'package:attendanceapp/Screens/student/student_dashbaord.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final Function toggleView;
  const LoginScreen({super.key, required this.toggleView});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  String error = '';
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    if (authState is AsyncLoading && !loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (authState is AsyncError && !loading) {
      error = authState.error.toString();
    }

    // Navigate based on role after successful login
    if (authState is AsyncData && authState.value != null && !loading) {
      // Use a microtask to avoid building during build
      Future.microtask(() {
        final userRole = authState.value!.role;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => userRole == 'lecturer'
                ? const LecturerDashboard()
                // : userRole == 'admin'
                //     ? const AdminDashboardScreen() // Replace with AdminDashboard
                    : StudentDashboard(),
          ),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
                onChanged: (value) => email = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
                onChanged: (value) => password = value,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      loading = true;
                      error = '';
                    });

                    // Use the AuthNotifier from Riverpod to handle sign-in
                    await ref
                        .read(authNotifierProvider.notifier)
                        .signIn(email, password);

                    // Check for errors after sign-in attempt
                    final currentState = ref.read(authNotifierProvider);
                    if (currentState is AsyncError) {
                      setState(() {
                        loading = false;
                        error = 'Login failed: ${currentState.error}';
                      });
                    }
                  }
                },
                child: const Text('Login'),
              ),
              TextButton(
                onPressed: () {
                  widget.toggleView();
                },
                child: const Text('Don\'t have an account? Sign Up'),
              ),
              if (error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    error,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
