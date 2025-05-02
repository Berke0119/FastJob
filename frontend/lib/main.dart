import 'dart:io';
import 'package:berkeserinfinal/user_state.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Platform.isAndroid
      ? await Firebase.initializeApp(
          options: const FirebaseOptions(
          apiKey: 'AIzaSyCAIlbzGFU9aiyhoa-2jnqWrjltPp8zt48',
          appId: '1:787669374452:android:456ccbd1e8991729bc15a1',
          messagingSenderId: '787669374452',
          projectId: 'freelancer-app-84f79',
          storageBucket: 'freelancer-app-84f79.appspot.com',
        ))
      : await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Firebase',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        primarySwatch: Colors.blue,
      ),
      home: UserState(),
    );
  }
}
