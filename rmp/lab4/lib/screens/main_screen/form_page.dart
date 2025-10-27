import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lab4/screens/main_screen/form_cubit_state.dart';
import 'package:lab4/screens/main_screen/form_cubit.dart';

class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: BackButton(
            onPressed: () {
              context.read<FormCubit>().goBack();
            },
          ),
          title: const Text('Results page')
      ),
      body: BlocBuilder<FormCubit, FormCubitState>(
        builder: (context, state) {
          if (state is FormCubitStateResultPage) {
            return Center(child: Text('${state.result}'));
          }
          return Container();
        },
      ),
    );
  }
}

class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  State<FormPage> createState() => _FormPageState();
}


class _FormPageState extends State<FormPage> {
  final _formKey = GlobalKey<FormState>();
  final _a = TextEditingController();
  final _b = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lab4')),
      body: BlocBuilder<FormCubit, FormCubitState>(
          builder: (context, state) {
            if (state is FormCubitStateFormPage) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(child: TextFormField(
                        decoration: InputDecoration(labelText: "a", errorText: state.aErrorMessage),
                        controller: _a,
                        keyboardType: TextInputType.number,
                        onChanged: (newValue) {
                          context.read<FormCubit>().changeA(newValue);
                        },
                      )),
                      Expanded(child: TextFormField(
                        decoration: InputDecoration(labelText: "b", errorText: state.bErrorMessage),
                        controller: _b,
                        keyboardType: TextInputType.number,
                        onChanged: (newValue) {
                          context.read<FormCubit>().changeB(newValue);
                        },
                      )),
                    ],
                  ),
                  CheckboxListTile(
                    value: state.sogl,
                    title: Text("Я ознакомлен с документом \"Согласие на обработку данных\""),
                    onChanged: (bool? value) => context.read<FormCubit>().changeSogl(!state.sogl),
                  ),
                  ElevatedButton(
                    onPressed: !state.sogl ? null : () {
                      context.read<FormCubit>().calculate();
                    },
                    child: Text("Calculate"),
                  ),
                ],
              );
            }
            return Container();
          }
      ),
    );
  }
}
