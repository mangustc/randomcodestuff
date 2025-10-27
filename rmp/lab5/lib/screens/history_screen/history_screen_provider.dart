import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lab5/screens/history_screen/history_cubit_state.dart';
import 'package:lab5/screens/history_screen/history_cubit.dart';
import 'package:lab5/screens/history_screen/history_page.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HistoryPage();
  }
}


class HistoryScreenProvider extends StatelessWidget {
  const HistoryScreenProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HistoryCubit(),
      child: HistoryScreen(),
    );
  }
}
