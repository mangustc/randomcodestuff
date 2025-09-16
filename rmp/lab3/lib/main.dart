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
        title: 'Lab 3',
        home: FirstScreen()
    );
  }
}

class FirstScreen extends StatefulWidget {
  const FirstScreen({super.key});

  @override
  State<FirstScreen> createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {
  final _formKey = GlobalKey<FormState>();
  final _a = TextEditingController();
  final _b = TextEditingController();
  bool _sogl = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text("Lab 3: FirstScreen"),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(child: TextFormField(
                  decoration: InputDecoration(labelText: "a"),
                  keyboardType: TextInputType.number,
                  controller: _a,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a value';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Enter a valid integer';
                    }
                    return null;
                  },
                )),
                Expanded(child: TextFormField(
                  decoration: InputDecoration(labelText: "b"),
                  keyboardType: TextInputType.number,
                  controller: _b,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a value';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Enter a valid integer';
                    }
                    return null;
                  },
                )),
              ],
            ),
            CheckboxListTile(
              value: _sogl,
              title: Text("Я ознакомлен с документом \"Согласие на обработку данных\" "),
              onChanged: (bool? value) => setState(() {
                _sogl = value!;
              }),
            ),
            ElevatedButton(
              onPressed: !_sogl ? null : () {
                if (_formKey.currentState!.validate()) {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => SecondScreen(a: int.parse(_a.text), b: int.parse(_b.text),)));
                }
              },
              child: Text("Calculate"),
            ),
          ],
        ),
      )
    );
  }
}

class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key, required this.a, required this.b});

  final int a;
  final int b;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text("Lab3: SecondScreen"),
      ),
      body: Center(
          child: Text("Result: ${pow(a + b, 3)}")
      ),
    );
  }
}
