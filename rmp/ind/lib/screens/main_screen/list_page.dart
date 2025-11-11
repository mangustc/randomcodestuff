import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ind/screens/main_screen/list_cubit.dart';
import 'package:ind/screens/main_screen/person_page.dart';
import 'package:ind/screens/main_screen/title_container.dart';
import 'package:ind/structures.dart';
import 'package:ind/util.dart' as util;

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
                    Stack(
                      children: [
                        Text(
                          "\n\n",
                          maxLines: 2,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          personFull.personFamilyName.toUpperCase(),
                          maxLines: 2,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Stack(
                      children: [
                        Text(
                          "\n\n",
                          maxLines: 2,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          personFull.personForename.toUpperCase(),
                          maxLines: 2,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Text(
                      "${util.calculateAge(personFull.personBirthDate)} years old",
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

class ListPage extends StatefulWidget {
  const ListPage({super.key});

  @override
  State<ListPage> createState() => _ListPageState();
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
                  initialValue: _selectedGender,
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
                  initialValue: _selectedNationalityCountryID,
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
                  initialValue: _selectedWantedByCountryID,
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