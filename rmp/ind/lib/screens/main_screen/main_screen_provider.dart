import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ind/screens/main_screen/list_cubit.dart';
import 'package:ind/screens/main_screen/list_page.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ListCubit, ListCubitState>(
      builder: (context, state) {
        return ListPage();
      },
    );
  }
}

class MainScreenProvider extends StatelessWidget {
  const MainScreenProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ListCubit(),
      child: MainScreen(),
    );
  }
}
