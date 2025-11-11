import 'package:flutter/material.dart';
import 'package:ind/screens/main_screen/title_container.dart';
import 'package:ind/util.dart' as util;
import 'package:ind/structures.dart';

class InfoText extends StatelessWidget {
  final String name;
  final String value;

  const InfoText({
    super.key,
    required this.name,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              name,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PersonPage extends StatelessWidget {
  const PersonPage({super.key, required this.personFull});

  final PersonFull personFull;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("${personFull.personFamilyName} ${personFull.personForename}"),
        ),
        body: SingleChildScrollView(child: Column(
          children: <Widget>[
            TitleContainer(
              child: Column(
                children: [
                  Text(
                    "${personFull.personFamilyName}, ${personFull.personForename}".toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  RichText(
                      text: TextSpan(
                        style: (Theme.of(context).textTheme.bodyMedium ?? TextStyle()).copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        children: [
                          TextSpan(
                            text: "Wanted by ",
                          ),
                          TextSpan(
                              text: personFull.personWantedByCountryName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              )
                          )
                        ],
                      )
                  ),
                ],
              ),
            ),
            SizedBox(height: 20,),
            Padding(
              padding: EdgeInsets.only(left: 12, right: 12),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Image.asset(
                      personFull.personAssetImagePath,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                  SizedBox(height: 20,),
                  InfoText(name: "Family name", value: personFull.personFamilyName),
                  InfoText(name: "Forename", value: personFull.personForename),
                  InfoText(name: "Gender", value: personFull.personGenderName),
                  InfoText(name: "Date of birth", value: "${personFull.personBirthDate.day}/${personFull.personBirthDate.month}/${personFull.personBirthDate.year} (${util.calculateAge(personFull.personBirthDate)} years old)"),
                  InfoText(name: "Nationality", value: personFull.personNationalityCountryName,),
                  if (personFull.personDetails != "") InfoText(name: "Details", value: personFull.personDetails,),
                  if (personFull.personPhysicalCharacteristics != "") InfoText(name: "Physical characteristics", value: personFull.personPhysicalCharacteristics,),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Charges",
                          style: TextStyle(
                            fontSize: 24,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 4, bottom: 20),
                          child: Text(
                            "Published as provided by requesting entity",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        Text(
                          personFull.personCharges,
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20,),
                ],
              ),
            ),
          ],
        ))
    );
  }
}