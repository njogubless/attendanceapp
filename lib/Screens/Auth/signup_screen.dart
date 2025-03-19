// FILE: lib/Screens/Auth/signup_screen.dart
import 'package:attendanceapp/Providers/auth_providers.dart';
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
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formkey = GlobalKey<FormState>();
  bool loading = false;

  String name = '';
  String email = '';
  String password = '';
  String regNo = '';
  String role = 'student';
  Role selectedRole = Role.student;

  String error = '';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // Handle error states
    if (authState is AsyncError && !loading) {
      error = authState.error.toString();
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
                      style: TextStyle(
                          fontSize: 80.0, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16.0, 70.0, 0.0, 0.0),
                  child: const Text('Sign Up',
                      style: TextStyle(
                          fontSize: 80.0, fontWeight: FontWeight.bold)),
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
                padding:
                    const EdgeInsets.only(top: 5.0, left: 20.0, right: 20.0),
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
                            labelText: 'REGISTRATION NUMBER',
                            labelStyle: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                color: darkGrey),
                            focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: lightBlue))),
                        validator: (val) => val!.trim().isEmpty
                            ? 'Enter a valid registration number'
                            : null,
                        onChanged: (val) {
                          setState(() {
                            regNo = val.trim();
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
                        value: selectedRole,
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

                              try {
                                // Register the user without signing in
                                await ref
                                    .read(authNotifierProvider.notifier)
                                    .registerOnly(
                                      email: email,
                                      password: password,
                                      name: name,
                                      role: role,
                                      regNo: regNo,
                                    );

                                if (mounted) {
                                  // Show success message
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text(
                                        'Registration successful! Please log in.'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 3),
                                  ));

                                  // Switch to login view
                                  setState(() {
                                    loading = false;
                                  });
                                  widget.toggleView();
                                }
                              } catch (e) {
                                // Handle error
                                if (mounted) {
                                  setState(() {
                                    loading = false;
                                    error =
                                        'Registration failed: ${e.toString()}';
                                  });
                                }
                              }
                            }
                          },
                          child: Material(
                            borderRadius: BorderRadius.circular(20.0),
                            shadowColor: Colors.blueAccent,
                            color: Colors.blue,
                            elevation: 7.0,
                            child: Center(
                              child: loading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    )
                                  : const Text(
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
            if (error.isNotEmpty)
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
                ],
              )
          ],
        ),
      ),
    );
  }
}