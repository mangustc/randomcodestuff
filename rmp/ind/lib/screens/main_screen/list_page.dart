import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ind/screens/main_screen/list_cubit.dart';
import 'package:ind/structures.dart';

class ListPage extends StatefulWidget {
  const ListPage({super.key});

  @override
  State<ListPage> createState() => _ListPageState();
}


class PersonConcise extends StatelessWidget {
  const PersonConcise({super.key, required this.personFull});

  final PersonFull personFull;

  @override
  Widget build(BuildContext context) {
    return Container(child: Image.asset(personFull.personAssetImagePath),);
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
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {

              },
            );
          },
        ),
        title: const Text('ind'),
      ),
      body: BlocBuilder<ListCubit, ListCubitState>(
          builder: (context, state) {
            return Column(
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
                // PersonConcise(personFull: PersonFull(personAssetImagePath: "assets/images/dexter.jpg"))
              ],
            );
          }
      ),
    );
  }
}
