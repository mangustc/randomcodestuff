class Person {
  int personID;
  String personFamilyName;
  String personForename;
  int personGender;
  int personNationalityCountryID;
  int personWantedByCountryID;
  DateTime personBirthDate;
  String personAssetImagePath;
  String personPhysicalCharacteristics;
  String personDetails;
  String personCharges;

  Person({
    required this.personID,
    required this.personFamilyName,
    required this.personForename,
    required this.personGender,
    required this.personNationalityCountryID,
    required this.personWantedByCountryID,
    required this.personBirthDate,
    required this.personPhysicalCharacteristics,
    required this.personDetails,
    required this.personCharges,
    required this.personAssetImagePath,
  });
}

class Country {
  int countryID;
  String countryName;

  Country({
    required this.countryID,
    required this.countryName,
  });
}

class PersonFull {
  String personFamilyName;
  String personForename;
  String personGenderName;
  String personNationalityCountryName;
  String personWantedByCountryName;
  DateTime personBirthDate;
  String personPhysicalCharacteristics;
  String personDetails;
  String personCharges;
  String personAssetImagePath;

  PersonFull({
    required this.personFamilyName,
    required this.personForename,
    required this.personGenderName,
    required this.personNationalityCountryName,
    required this.personWantedByCountryName,
    required this.personBirthDate,
    required this.personPhysicalCharacteristics,
    required this.personDetails,
    required this.personCharges,
    required this.personAssetImagePath,
  });

  factory PersonFull.fromMap(Map<String, dynamic> map) {
    // Map gender integer to string
    String genderName;
    switch (map["personGender"]) {
      case 0:
        genderName = 'Unknown';
        break;
      case 1:
        genderName = 'Male';
        break;
      case 2:
        genderName = 'Female';
        break;
      default:
        genderName = 'Other';
    }

    return PersonFull(
      personFamilyName: map['personFamilyName'] ?? '',
      personForename: map['personForename'] ?? '',
      personGenderName: genderName,
      personNationalityCountryName: map['nationalityCountryName'] ?? '',
      personWantedByCountryName: map['wantedByCountryName'] ?? '',
      personBirthDate: DateTime.parse(map['personBirthDate']),
      personPhysicalCharacteristics: map['personPhysicalCharacteristics'] ?? '',
      personDetails: map['personDetails'] ?? '',
      personCharges: map['personCharges'] ?? '',
      personAssetImagePath: map['personAssetImagePath'] ?? '',
    );
  }
}

class PersonFilter {
  String? personFamilyName;
  String? personForename;
  int? personGender;
  int? personNationalityCountryID;
  int? personWantedByCountryID;
  int? personCurrentAgeFrom;
  int? personCurrentAgeTo;
  String? personKeywords;

  PersonFilter({
    this.personFamilyName,
    this.personForename,
    this.personGender,
    this.personNationalityCountryID,
    this.personWantedByCountryID,
    this.personCurrentAgeFrom,
    this.personCurrentAgeTo,
    this.personKeywords,
  });
}