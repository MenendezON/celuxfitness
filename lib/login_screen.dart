import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  Future<void> login() async {
    setState(() {
      isLoading = true;
    });

    try {
      String fakeEmail = "${usernameController.text.trim()}@celuxfitness.sn";

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: fakeEmail,
        password: passwordController.text.trim(),
      );

      // ✅ Success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Login successful ✅"),
          backgroundColor: Colors.green,
        ),
      );

      User user = FirebaseAuth.instance.currentUser!;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(email: user.email ?? ""),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'user-not-found':
          message = "User not found";
          break;
        case 'wrong-password':
          message = "Incorrect password";
          break;
        case 'invalid-email':
          message = "Invalid username";
          break;
        case 'network-request-failed':
          message = "No internet connection";
          break;
        default:
          message = "Auth error: ${e.code}";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      print("ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/celux_logo.png',
              width: 175,
              height: 175,
              fit: BoxFit.cover, // Options: contain, cover, fill, etc.
            ),
            Text(
              "Celux Fitness",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : login,

              child: isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text("Login"),
            ),
            SizedBox(height: 68),
          ],
        ),
      ),
    );
  }
}
