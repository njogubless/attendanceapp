import 'package:attendanceapp/Screens/Auth/Login_Screen.dart';
import 'package:flutter/material.dart';

import 'package:attendanceapp/Screens/Auth/signup_screen.dart';

class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  _AuthenticationWrapperState createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  bool showSignIn = true;

  void toggleView() {
    setState(() {
      showSignIn = !showSignIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showSignIn) {
      return LoginScreen(toggleView: toggleView);
    } else {
      return SignupScreen(toggleView: toggleView);
    }
  }
}