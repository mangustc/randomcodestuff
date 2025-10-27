import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lab4/screens/main_screen/form_cubit_state.dart';
import 'package:lab4/screens/main_screen/form_cubit.dart';
import 'package:lab4/screens/main_screen/form_page.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FormCubit, FormCubitState>(
      builder: (context, state) {
        if (state is FormCubitStateFormPage) {
          return FormPage();
        } else if (state is FormCubitStateResultPage) {
          return ResultsPage();
        }
        return Scaffold(
          appBar: AppBar(title: const Text('ERROR PAGE')),
          body: Center(child: Text('Error page')),
        );

      },
    );
  }
}


class MainScreenProvider extends StatelessWidget {
  const MainScreenProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FormCubit(),
      child: MainScreen(),
    );
  }
}
