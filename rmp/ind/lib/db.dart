import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:ind/structures.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DBProvider {
  DBProvider._();

  static final DBProvider db = DBProvider._();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final documentsDir = await getApplicationDocumentsDirectory();
    final dbPath = "${documentsDir.path}/app.db";
    final file = File(dbPath);
    final data = await rootBundle.load("assets/app.db");
    final bytes = data.buffer.asUint8List();
    await file.writeAsBytes(bytes);
    _database = await openDatabase(dbPath, readOnly: true);

    // _database = await openDatabase('assets/app.db', readOnly: true);

    return _database!;
  }

  Future<List<PersonFull>> getPersonFullList(PersonFilter filter) async {
    Database db = await this.database;

    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (filter.personFamilyName != null) {
      whereClauses.add("p.personFamilyName LIKE ?");
      whereArgs.add('%${filter.personFamilyName}%');
    }
    if (filter.personForename != null) {
      whereClauses.add("p.personForename LIKE ?");
      whereArgs.add('%${filter.personForename}%');
    }
    if (filter.personGender != null) {
      whereClauses.add("p.personGender = ?");
      whereArgs.add(filter.personGender);
    }
    if (filter.personNationalityCountryID != null) {
      whereClauses.add("p.personNationalityCountryID = ?");
      whereArgs.add(filter.personNationalityCountryID);
    }
    if (filter.personWantedByCountryID != null) {
      whereClauses.add("p.personWantedByCountryID = ?");
      whereArgs.add(filter.personWantedByCountryID);
    }
    if (filter.personCurrentAgeFrom != null || filter.personCurrentAgeTo != null) {
      final currentDate = DateTime.now();
      if (filter.personCurrentAgeFrom != null) {
        DateTime maxBirthDate = DateTime(currentDate.year - filter.personCurrentAgeFrom!, currentDate.month, currentDate.day);
        whereClauses.add("p.personBirthDate <= ?");
        whereArgs.add(maxBirthDate.toIso8601String());
      }
      if (filter.personCurrentAgeTo != null) {
        DateTime minBirthDate = DateTime(currentDate.year - filter.personCurrentAgeTo! - 1, currentDate.month, currentDate.day).add(Duration(days: 1));
        whereClauses.add("p.personBirthDate >= ?");
        whereArgs.add(minBirthDate.toIso8601String());
      }
    }
    if (filter.personKeywords != null) {
      List<String> keywordClauses = [];
      List<dynamic> keywordArgs = [];
      var keywords = filter.personKeywords!.split(' ');
      for (var keyword in keywords) {
        var likePattern = '%$keyword%';
        keywordClauses.add("(p.personPhysicalCharacteristics LIKE ? OR p.personDetails LIKE ? OR p.personCharges LIKE ?)");
        keywordArgs.addAll([likePattern, likePattern, likePattern]);
      }
      whereClauses.add(keywordClauses.join(" AND "));
      whereArgs.addAll(keywordArgs);
    }

    String whereString = whereClauses.isNotEmpty ? "WHERE " + whereClauses.join(" AND ") : "";

    final List<Map<String, dynamic>> result = await db.rawQuery('''
SELECT
  p.personFamilyName,
  p.personForename,
  p.personGender,
  p.personBirthDate,
  p.personPhysicalCharacteristics,
  p.personDetails,
  p.personCharges,
  p.personAssetImagePath,
  c1.countryName AS nationalityCountryName,
  c2.countryName AS wantedByCountryName
FROM Person p
JOIN Country c1 ON p.personNationalityCountryID = c1.countryID
JOIN Country c2 ON p.personWantedByCountryID = c2.countryID
$whereString
''', whereArgs);

    return result.map((map) => PersonFull.fromMap(map)).toList();
  }

  Future<List<Country>> getCountryList() async {
    Database db = await this.database;
    final List<Map<String, dynamic>> result = await db.query('Country');
    return result.map((map) => Country.fromMap(map)).toList();
  }
}