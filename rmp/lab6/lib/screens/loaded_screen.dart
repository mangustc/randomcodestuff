import 'package:flutter/material.dart';
import 'package:lab6/models.dart';

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
            loadingBuilder: (context, child, imageEvent) {
              if (imageEvent != null) {
                return Center(
                  child: CircularProgressIndicator(
                    value: imageEvent.expectedTotalBytes != null ? imageEvent.cumulativeBytesLoaded / imageEvent.expectedTotalBytes! : null,
                  ),
                );
              } else {
                return child;
              }
            },
          ) : failedLoadPhoto,
          SizedBox(width: 16),
          // Textual information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
