// Changes to SignupScreen to improve role selection and navigation
import 'package:attendanceapp/Providers/auth_providers.dart';
import 'package:attendanceapp/Screens/lecturer/lecturer_dashboard.dart';
import 'package:attendanceapp/Screens/student/student_dashbaord.dart';
import 'package:attendanceapp/core/constants/Color/color_constants.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum Role { admin, lecturer, student }

class SignupScreen extends ConsumerStatefulWidget {
  final Function toggleView;
  const SignupScreen({super.key, required this.toggleView});

  @override
  ConsumerState<SignupScreen> createState() => _RegisterClientState();
}

class _RegisterClientState extends ConsumerState<SignupScreen> {
  final _formkey = GlobalKey<FormState>();
  bool loading = false;

  String name = '';
  String email = '';
  String password = '';
  String role = 'student'; // Default role
  Role selectedRole = Role.student; // Default selected role

  String error = '';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // if (authState is AsyncLoading && !loading) {
    //   return const Center(child: CircularProgressIndicator()); // Replace with your Loading widget
    // }

    if (authState is AsyncError && !loading) {
      error = authState.error.toString();
    }

    // Navigate based on role after successful registration
    if (authState is AsyncData && authState.value != null && !loading) {
      // Use a microtask to avoid building during build
      Future.microtask(() {
        final userRole = authState.value!.role;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => userRole == 'lecturer' 
              ? const LecturerDashboard() 
              : StudentDashboard(),
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: white,
        elevation: 0.0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Stack(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.fromLTRB(15.0, 0.0, 0.0, 0.0),
                  child: const Text('Do',
                      style:
                          TextStyle(fontSize: 80.0, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16.0, 70.0, 0.0, 0.0),
                  child: const Text('Sign Up',
                      style:
                          TextStyle(fontSize: 80.0, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(310.0, 70.0, 0.0, 0.0),
                  child: const Text('.',
                      style: TextStyle(
                        fontSize: 80.0,
                        fontWeight: FontWeight.bold,
                        color: lightBlue,
                      )),
                )
              ],
            ),
            Container(
                padding: const EdgeInsets.only(top: 5.0, left: 20.0, right: 20.0),
                child: Form(
                  key: _formkey,
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        decoration: const InputDecoration(
                            labelText: 'YOUR NAME',
                            labelStyle: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                color: darkGrey),
                            focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: lightBlue))),
                        validator: (val) => val!.trim().isEmpty
                            ? 'Enter a name consisting of 1+ characters'
                            : null,
                        onChanged: (val) {
                          setState(() {
                            name = val.trim();
                          });
                        },
                      ),
                      const SizedBox(height: 20.0),
                      TextFormField(
                        decoration: const InputDecoration(
                            labelText: 'EMAIL',
                            labelStyle: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                color: darkGrey),
                            focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: lightBlue))),
                        validator: (val) => EmailValidator.validate(val!.trim())
                            ? null
                            : 'Enter a valid email address',
                        onChanged: (val) {
                          setState(() {
                            email = val.trim();
                          });
                        },
                      ),
                      const SizedBox(height: 20.0),
                      TextFormField(
                        decoration: const InputDecoration(
                            labelText: 'PASSWORD',
                            labelStyle: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                color: darkGrey),
                            focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: lightBlue))),
                        validator: (val) => val!.trim().length < 6
                            ? 'Password less than 6 characters long'
                            : null,
                        onChanged: (val) {
                          setState(() {
                            password = val.trim();
                          });
                        },
                        obscureText: true,
                      ),
                      const SizedBox(height: 20.0),
                      DropdownButtonFormField<Role>(
                        value: selectedRole, // Set initial value to prevent null
                        decoration: const InputDecoration(
                            labelText: 'ROLE',
                            labelStyle: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                color: darkGrey),
                            focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: lightBlue))),
                        items: const [
                          DropdownMenuItem(
                            value: Role.admin,
                            child: Text('Admin'),
                          ),
                          DropdownMenuItem(
                            value: Role.lecturer,
                            child: Text('Lecturer'),
                          ),
                          DropdownMenuItem(
                            value: Role.student,
                            child: Text('Student'),
                          ),
                        ],
                        onChanged: (item) {
                          setState(() {
                            selectedRole = item!;
                            switch (item) {
                              case Role.student:
                                role = 'student';
                                break;
                              case Role.admin:
                                role = 'admin';
                                break;
                              case Role.lecturer:
                                role = 'lecturer';
                                break;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 45.0),
                      SizedBox(
                        height: 40.0,
                        child: GestureDetector(
                          onTap: () async {
                            if (_formkey.currentState!.validate()) {
                              setState(() {
                                loading = true;
                                error = '';
                              });
        
                              // Use the AuthNotifier from Riverpod to handle sign-up
                              await ref
                                  .read(authNotifierProvider.notifier)
                                  .signUp(
                                    email: email,
                                    password: password,
                                    name: name,
                                    role: role,
                                  );
        
                              // Check for errors after sign-up attempt
                              final currentState = ref.read(authNotifierProvider);
                              if (currentState is AsyncError) {
                                setState(() {
                                  loading = false;
                                  error =
                                      'Registration failed: ${currentState.error}';
                                });
                              }
                            }
                          },
                          child: Material(
                            borderRadius: BorderRadius.circular(20.0),
                            shadowColor: Colors.blueAccent,
                            color: Colors.blue,
                            elevation: 7.0,
                            child: const Center(
                              child: Text(
                                'REGISTER',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Montserrat'),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20.0),
                    ],
                  ),
                )),
            const SizedBox(height: 15.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'Already have an account?',
                  style: TextStyle(fontFamily: 'Montserrat'),
                ),
                const SizedBox(width: 5.0),
                InkWell(
                  onTap: () {
                    widget.toggleView();
                  },
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                        color: lightBlue,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline),
                  ),
                )
              ],
            ),
            const SizedBox(height: 15.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  error,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 5.0),
              ],
            )
          ],
        ),
      ),
    );
  }
}