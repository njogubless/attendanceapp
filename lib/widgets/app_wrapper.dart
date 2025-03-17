import 'package:attendanceapp/Providers/auth_providers.dart';
import 'package:attendanceapp/Screens/Auth/auth_wrapper.dart';
import 'package:attendanceapp/Screens/Auth/signup_screen.dart';
import 'package:attendanceapp/Screens/lecturer/lecturer_dashboard.dart';
import 'package:attendanceapp/Screens/student/student_dashbaord.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppWrapper extends ConsumerWidget {
  const AppWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (User? user) {
        if (user == null) {
          // Clear any cached user data state when logged out
          ref.invalidate(userDataProvider);
          return const AuthenticationWrapper();
        } else {
          // User is logged in, fetch user data
          final userData = ref.watch(userDataProvider);
          
          return userData.when(
            data: (userModel) {
              if (userModel == null) {
                // Something went wrong, log out and return to auth screen
                // Wrap in a builder to get a fresh context
                return Builder(
                  builder: (context) {
                    // Use Future.microtask to avoid build-time side effects
                    Future.microtask(() => FirebaseAuth.instance.signOut());
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                );
              }
              
              // Route based on user role
              switch (userModel.role) {
                case 'lecturer':
                  return const LecturerDashboard();
                case 'admin':
                  return SignupScreen(toggleView: () {}); // Replace with AdminDashboard
                case 'student':
                default:
                  return StudentDashboard();
              }
            },
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) {
              // Error fetching user data, log out
              // Wrap in a builder to get a fresh context
              return Builder(
                builder: (context) {
                  // Use Future.microtask to avoid build-time side effects
                  Future.microtask(() => FirebaseAuth.instance.signOut());
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
              );
            },
          );
        }
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const AuthenticationWrapper(),
    );
  }
}