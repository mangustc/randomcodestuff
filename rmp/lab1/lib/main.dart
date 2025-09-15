import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    title: 'Lab 1',
    home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.red,
          title: Text("Lab 1"),
        ),
        body: Text("RMP", style: TextStyle(fontSize: 40, decoration: TextDecoration.overline),),
    ),
  ));
}
