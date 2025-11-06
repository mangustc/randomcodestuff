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
    ''');
    return result.map((map) => PersonFull.fromMap(map)).toList();
  }

  Future<List<Country>> getCountryList() async {
    Database db = await this.database;
    final List<Map<String, dynamic>> result = await db.query('Country');
    return result.map((map) => Country.fromMap(map)).toList();
  }
}