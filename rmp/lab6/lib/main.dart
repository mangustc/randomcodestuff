import 'package:flutter/material.dart';
import 'dart:math';

import 'api.dart';
import 'models.dart';

void main() {
  runApp(const MyApp());
}


Future<List<Character>> getCharacterList() async {
  var characterData = await getCharacterData();
  return characterData.map((json) => Character.fromJson(json)).toList();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Lab 6',
        home: LoadingScreen()
    );
  }
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

final failedLoadPhoto = Container(
    width: 80,
    height: 80,
    color: Colors.grey[300],
    child: Icon(Icons.person, size: 50, color: Colors.grey[600]));

class CharacterInfo extends StatelessWidget {
  final Character character;

  const CharacterInfo({super.key, required this.character});

  String _getWandInfo(Wand? wand) {
    if (wand == null) return 'Wand: Unknown';
    final wood = wand.wood == null || wand.wood!.isEmpty ? 'Unknown wood' : wand.wood;
    final core = wand.core == null || wand.core!.isEmpty ? 'Unknown core' : wand.core;
    final length = wand.length == null ? 'Unknown length' : '${wand.length} inches';
    return 'Wand: $wood, $core, $length';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          (character.image != null && character.image!.isNotEmpty) ? Image.network(
            character.image!,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) { return failedLoadPhoto; },
          ) : failedLoadPhoto,
          SizedBox(width: 16),
          // Textual information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  character.name ?? 'Unknown',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Date of Birth: ${character.dateOfBirth ?? 'Unknown'}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  _getWandInfo(character.wand),
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LoadedScreen extends StatelessWidget {
  final List<Character> characterList;

  const LoadedScreen({super.key, required this.characterList});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text("Harry Potter Characters"),
      ),
      body: ListView.builder(
          itemCount: characterList.length,
          itemBuilder: (context, index) {
            return CharacterInfo(character: characterList[index]);
          }
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String errorMessage;

  const ErrorScreen({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Error happened',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(errorMessage, textAlign: TextAlign.center),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoadingScreen()),
                  );
                },
                child: Text('Retry'),
              )
            ],
          ),
        ),
      ),
    );
  }
}