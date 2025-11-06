import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ind/screens/main_screen/list_cubit.dart';
import 'package:ind/structures.dart';

class ListPage extends StatefulWidget {
  const ListPage({super.key});

  @override
  State<ListPage> createState() => _ListPageState();
}

int calculateAge(DateTime birthDate) {
  DateTime currentDate = DateTime.now();
  int age = currentDate.year - birthDate.year;

  // Adjust age if the birthday hasn't occurred yet this year
  if (currentDate.month < birthDate.month ||
      (currentDate.month == birthDate.month && currentDate.day < birthDate.day)) {
    age--;
  }
  return age;
}



class InfoText extends StatelessWidget {
  const InfoText({super.key, required this.name, required this.value});

  final String name;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(name),
        Text(value),
      ],
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
          Image.asset(personFull.personAssetImagePath,),
          InfoText(name: "Family name", value: personFull.personFamilyName),
          InfoText(name: "Forename", value: personFull.personForename),
          InfoText(name: "Gender", value: personFull.personGenderName),
          InfoText(name: "Date of birth", value: "${personFull.personBirthDate.day}/${personFull.personBirthDate.month}/${personFull.personBirthDate.year} (${calculateAge(personFull.personBirthDate)} years old)"),
          InfoText(name: "Nationality", value: personFull.personNationalityCountryName,),
          InfoText(name: "WantedBy", value: personFull.personWantedByCountryName,),
          InfoText(name: "Details", value: personFull.personDetails,),
          InfoText(name: "Physical characteristics", value: personFull.personPhysicalCharacteristics,),
          InfoText(name: "Charges", value: personFull.personCharges,),
        ],
      ))
    );

  }
}
class PersonConcise extends StatelessWidget {
  const PersonConcise({super.key, required this.personFull});

  final PersonFull personFull;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(
              builder: (context) => PersonPage(personFull: personFull,)
          ));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(personFull.personAssetImagePath, width: 120, height: 120,),
            Text(personFull.personFamilyName),
            Text(personFull.personForename),
            Text("${calculateAge(personFull.personBirthDate)} years old"),
            Text(personFull.personNationalityCountryName),
          ],
        )
    );
  }
}

class _ListPageState extends State<ListPage> {
  final _formKey = GlobalKey<FormState>();
  final _familyNameController = TextEditingController();
  final _forenameController = TextEditingController();
  final _currentAgeFromController = TextEditingController();
  final _currentAgeToController = TextEditingController();
  int? _selectedGender;
  int? _selectedNationalityID;
  int? _selectedWantedByID;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ind'),
      ),
      body: BlocBuilder<ListCubit, ListCubitState>(
          builder: (context, state) {
            if (state.countryList.isEmpty) {
              context.read<ListCubit>().updateSearch(PersonFilter());
            }
            return SingleChildScrollView(child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(child: TextFormField(
                      decoration: InputDecoration(labelText: "Family Name"),
                      controller: _familyNameController,
                      keyboardType: TextInputType.text,
                      onChanged: (newValue) {
                        // context.read<FormCubit>().changeA(newValue);
                      },
                    )),
                  ],
                ),
                Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (var personFull in state.personFullList)
                      PersonConcise(personFull: personFull),
                  ],
                )
              ],
            ));
          }
      ),
    );
  }
}
