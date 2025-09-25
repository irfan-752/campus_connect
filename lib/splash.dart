import 'package:campus_connect/login.dart';
import 'package:flutter/material.dart';

class CampusSplashScreen extends StatelessWidget {
  const CampusSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    });
    return Scaffold(
      backgroundColor: Colors.white, // white base
      body: Stack(
        children: [
          // Background PNG
          Positioned.fill(
            child: Image.asset(
              "assets/images/Background.png", // your background PNG
              fit: BoxFit.cover,
            ),
          ),

          // Center text
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  "campus",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  "connect",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: Colors.lightBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
