import 'package:flutter/material.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aid Tracker Boilerplate',
      home: Scaffold(
        body: const Center(child: Text('Initializing...')),
      ),
    );
  }
}
