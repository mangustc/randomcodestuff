DROP TABLE IF EXISTS Country;
DROP TABLE IF EXISTS Person;

CREATE TABLE Person (
  personID INTEGER PRIMARY KEY,
  personFamilyName TEXT NOT NULL DEFAULT '',
  personForename TEXT NOT NULL DEFAULT '',
  personGender INTEGER NOT NULL,
  personNationalityCountryID INTEGER NOT NULL,
  personWantedByCountryID INTEGER NOT NULL,
  personBirthDate TEXT NOT NULL,
  personAssetImagePath TEXT NOT NULL DEFAULT '',
  personPhysicalCharacteristics TEXT NOT NULL DEFAULT '',
  personDetails TEXT NOT NULL DEFAULT '',
  personCharges TEXT NOT NULL DEFAULT '',
  FOREIGN KEY(personNationalityCountryID) REFERENCES Country(countryID),
  FOREIGN KEY(personWantedByCountryID) REFERENCES Country(countryID)
);

CREATE TABLE Country (
  countryID INTEGER PRIMARY KEY,
  countryName TEXT NOT NULL DEFAULT '' UNIQUE
);

INSERT INTO Country (countryID, countryName) VALUES
  (1, 'United States'),
  (2, 'UK'),
  (3, 'France');

INSERT INTO Person (
  personFamilyName, personForename, personGender, personNationalityCountryID,
  personWantedByCountryID, personBirthDate, personAssetImagePath, personPhysicalCharacteristics,
  personDetails, personCharges
) VALUES
  ('Doe', 'John', 1, 1, 1, '1980-01-15T00:00:00', 'assets/images/dexter.jpg', 'Height: 180cm, Hair: Brown', 'No additional details', 'Robbery'),
  ('Smith', 'Jane', 2, 2, 2, '1990-05-30T00:00:00', 'assets/images/dexter.jpg', 'Height: 165cm, Hair: Blonde', 'Known to carry a weapon', 'Fraud'),
  ('Dubois', 'Claire', 2, 3, 3, '1975-09-12T00:00:00', 'assets/images/dexter.jpg', 'Height: 170cm, Eye Color: Green', '', 'Smuggling');
