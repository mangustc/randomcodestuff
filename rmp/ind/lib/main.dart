import 'package:flutter/material.dart';
import 'package:ind/screens/main_screen/main_screen_provider.dart';

void main() {
  runApp(MaterialApp(
      home: MainScreenProvider(),
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Color(0xFF003366),
        secondaryHeaderColor: Color(0xFFD4AF37),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF003366),
          elevation: 2,
          iconTheme: IconThemeData(color: Color(0xFF003366)),
        ),
        textTheme: TextTheme(
          // bodyLarge: TextStyle(fontSize: 20),
          // bodyMedium: TextStyle(fontSize: 16),
          // bodySmall: TextStyle(fontSize: 12),
          // displayLarge: TextStyle(fontSize: 16),
          // displayMedium: TextStyle(fontSize: 16),
          // displaySmall: TextStyle(fontSize: 16),
          // headlineLarge: TextStyle(fontSize: 16),
          // headlineMedium: TextStyle(fontSize: 16),
          // headlineSmall: TextStyle(fontSize: 16),
          // titleLarge: TextStyle(fontSize: 16),
          // titleMedium: TextStyle(fontSize: 16),
          // titleSmall: TextStyle(fontSize: 16),
        ),
        colorScheme: ColorScheme.light(
          primary: Color(0xFF003366),
          secondary: Color(0xFFD4AF37),
          onPrimary: Colors.white,
        ),
      ),
  ));
}
