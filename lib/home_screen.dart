import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final String email;
  const HomeScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: NetworkImage('https://img.freepik.com/premium-vector/man-avatar-profile-picture-isolated-background-avatar-profile-picture-man_1293239-4855.jpg'),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(email.split('@')[0], style: TextStyle(fontSize: 15 ,fontWeight: FontWeight.bold),),
                    Text('status')
                  ],
                ),
              ],
            ),
            ListTile(
              title: const Text("Mon abonnement"),
              onTap: () {},
            ),
            ListTile(
              title: const Text("Réserver un coach"),
              onTap: () {},
            ),
            ListTile(
              title: const Text("Check-in"),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}