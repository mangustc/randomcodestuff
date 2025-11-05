import 'dart:io';

import 'package:ind/structures.dart';
import 'package:sqflite/sqflite.dart';

class DBProvider {
  DBProvider._();

  static final DBProvider db = DBProvider._();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDB();
    return _database!;
  }
  Future<Database> _initDB() async {
    return await openDatabase("assets/app.db", version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute("""""");
  }

  Future<List<PersonFull>> getPersonFullList() async {
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
}