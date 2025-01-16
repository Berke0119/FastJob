import 'package:berkeserinfinal/Jobs/jobs_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'LoginPage/login_screen.dart';

class UserState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, userSnapshot) {
          if (userSnapshot.data == null) {
            print('User is not logged in');
            return Login();
          } else if (userSnapshot.hasData) {
            print('User is already logged in');
            return JobScreen();
          } else if (userSnapshot.hasError) {
            return const Scaffold(
              body: Center(
                child: Text('An error has been occured. Try again later.'),
              ),
            );
          } else if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: Colors.cyan,
                ),
              ),
            );
          }
          return const Scaffold(
            body: Center(
              child: Text('Sometihng went wrong.'),
            ),
          );
        });
  }
}
