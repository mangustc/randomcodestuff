import 'package:flutter/material.dart';
import 'package:lab6/api.dart';
import 'package:lab6/models.dart';

import 'package:lab6/screens/loaded_screen.dart';
import 'package:lab6/screens/error_screen.dart';

Future<List<Character>> getCharacterList() async {
  var characterData = await getCharacterData();
  return characterData.map((json) => Character.fromJson(json)).toList();
}

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {

  late Future<List<Character>> _futureCharacters;

  @override
  void initState() {
    super.initState();
    _futureCharacters = getCharacterList();
    _futureCharacters.then((characterList) => Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoadedScreen(characterList: characterList),),
    ),).catchError((error) => Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ErrorScreen(errorMessage: "error.toString()"),),
    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Loading..."),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        )
    );
  }
}
