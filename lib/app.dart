import 'package:flutter/material.dart';

import 'login_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Celux Fitness',
      debugShowCheckedModeBanner: false,

      home: LoginScreen(),
    );
  }
}
