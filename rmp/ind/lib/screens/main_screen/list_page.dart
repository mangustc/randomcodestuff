import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  if (currentDate.month < birthDate.month ||
      (currentDate.month == birthDate.month && currentDate.day < birthDate.day)) {
    age--;
  }
  return age;
}

class TitleContainer extends StatelessWidget {
  final Widget child;

  const TitleContainer({
    super.key,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.primary,
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: child,
    );
  }
}


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
                Image.asset(personFull.personAssetImagePath,),
                SizedBox(height: 20,),
                InfoText(name: "Family name", value: personFull.personFamilyName),
                InfoText(name: "Forename", value: personFull.personForename),
                InfoText(name: "Gender", value: personFull.personGenderName),
                InfoText(name: "Date of birth", value: "${personFull.personBirthDate.day}/${personFull.personBirthDate.month}/${personFull.personBirthDate.year} (${calculateAge(personFull.personBirthDate)} years old)"),
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
class PersonConcise extends StatelessWidget {
  const PersonConcise({super.key, required this.personFull});

  final PersonFull personFull;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 320,
      child: ElevatedButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(
                builder: (context) => PersonPage(personFull: personFull,)
            ));
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size(0, 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                personFull.personAssetImagePath,
                height: 150,
                fit: BoxFit.cover,
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${personFull.personFamilyName.toUpperCase()}\n",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${personFull.personForename.toUpperCase()}\n",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${calculateAge(personFull.personBirthDate)} years old",
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      personFull.personNationalityCountryName,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          )),
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
  int? _selectedNationalityCountryID;
  int? _selectedWantedByCountryID;
  final _keywordsController = TextEditingController();

  void _applyFilters() {
    final filter = PersonFilter(
        personFamilyName: _familyNameController.text.isEmpty ? null : _familyNameController.text,
        personForename: _forenameController.text.isEmpty ? null : _forenameController.text,
        personCurrentAgeFrom: _currentAgeFromController.text.isEmpty ? null : int.tryParse(_currentAgeFromController.text),
        personCurrentAgeTo: _currentAgeToController.text.isEmpty ? null : int.tryParse(_currentAgeToController.text),
        personGender: _selectedGender,
        personNationalityCountryID: _selectedNationalityCountryID,
        personWantedByCountryID: _selectedWantedByCountryID,
        personKeywords: _keywordsController.text.isEmpty ? null : _keywordsController.text
    );
    context.read<ListCubit>().updateSearch(filter);
  }

  void _showFilterDialog(BuildContext context, List<Country> countryList) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Filters"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Family Name'),
                  controller: _familyNameController,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Forename'),
                  controller: _forenameController,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(labelText: 'Age From'),
                        controller: _currentAgeFromController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(labelText: 'Age To'),
                        controller: _currentAgeToController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                        ],
                      ),
                    ),
                  ],
                ),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Gender'),
                  value: _selectedGender,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Any')),
                    const DropdownMenuItem(value: 0, child: Text('Unknown')),
                    const DropdownMenuItem(value: 1, child: Text('Male')),
                    const DropdownMenuItem(value: 2, child: Text('Female')),
                  ],
                  onChanged: (value) {
                    _selectedGender = value;
                  },
                ),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Nationality'),
                  value: _selectedNationalityCountryID,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Any')),
                    ...countryList.map((country) => DropdownMenuItem(
                      value: country.countryID,
                      child: Text(country.countryName),
                    )),
                  ],
                  onChanged: (value) {
                    _selectedNationalityCountryID = value;
                  },
                ),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Wanted By'),
                  value: _selectedWantedByCountryID,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Any')),
                    ...countryList.map((country) => DropdownMenuItem(
                      value: country.countryID,
                      child: Text(country.countryName),
                    )),
                  ],
                  onChanged: (value) {
                    _selectedWantedByCountryID = value;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Keywords'),
                  controller: _keywordsController,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () { Navigator.of(context).pop(); },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                _applyFilters();
                Navigator.of(context).pop();
              },
              child: const Text("Apply Filters"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SvgPicture.asset(
          "assets/interpol.svg",
          width: 40,
          height: 40,
          colorFilter: ColorFilter.mode(
              Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.primary,
              BlendMode.srcIn
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_alt,),
            onPressed: () {
              final state = context.read<ListCubit>().state;
              _showFilterDialog(context, state.countryList);
            },
          ),
        ],
      ),
      body: BlocBuilder<ListCubit, ListCubitState>(
        builder: (context, state) {
          if (state.countryList.isEmpty) {
            _applyFilters();
          }
          return SingleChildScrollView(
            child: Column(
              children: [
                TitleContainer(
                  child: Text(
                    "Wanted persons",
                    style: TextStyle(
                      fontSize: 32,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
                SizedBox(height: 20,),
                // MasonryGridView.builder(
                //   shrinkWrap: true,
                //   physics: NeverScrollableScrollPhysics(),
                //   padding: const EdgeInsets.all(12),
                //   mainAxisSpacing: 12,
                //   crossAxisSpacing: 12,
                //   gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                //     crossAxisCount: 2,
                //   ),
                //   itemCount: state.personFullList.length,
                //   itemBuilder: (context, index) {
                //     final personFull = state.personFullList[index];
                //     return PersonConcise(personFull: personFull);
                //   },
                // ),
                // Wrap(
                //   alignment: WrapAlignment.spaceBetween,
                //   spacing: 12,
                //   runSpacing: 12,
                //   children: [
                //     for (var personFull in state.personFullList) PersonConcise(personFull: personFull),
                //   ],
                // ),
                LayoutBuilder(
                    builder: (context, constraints) {
                      double itemWidth = 160;
                      int columnAmount = (constraints.maxWidth / itemWidth).floor();
                      int rowAmount = (state.personFullList.length / columnAmount).ceil();

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(0),

                        itemCount: rowAmount,
                        itemBuilder: (_, index) {
                          int startIndex = index * columnAmount;
                          int endIndex = startIndex + columnAmount - 1;
                          return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                for (int i = startIndex; i <= endIndex && i < state.personFullList.length; i++) PersonConcise(personFull: state.personFullList[i])
                              ]
                          );
                        },
                        separatorBuilder: (_, _) {
                          return SizedBox(height: 12,);
                        },
                      );
                    },
                ),
              ]
            ),
          );
        },
      ),
    );
  }
}