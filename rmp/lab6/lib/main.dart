import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Lab 6',
        home: MainScreen()
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lab 6: Main Screen"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {

          },
          child: Text("Load марсоход - curiosity, сол - 50")),
      )
    );
  }
}

class SecondScreen extends StatelessWidget {
  final int data;

  const SecondScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text("Lab6: Images"),
      ),
      body: Center(
        child: Text("Result: 1")
      ),
    );
  }
}
