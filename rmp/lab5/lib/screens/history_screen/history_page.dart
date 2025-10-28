import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lab5/screens/history_screen/history_cubit_state.dart';
import 'package:lab5/screens/history_screen/history_cubit.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('History page')
      ),
      body: BlocBuilder<HistoryCubit, HistoryCubitState>(
        builder: (context, state) {
          if (state is HistoryCubitStateHistoryPage) {
            return SingleChildScrollView(child: Column(
              children: <Widget>[
                for (var item in state.resultList)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("a: ${item[0]}"),
                      Text("b: ${item[1]}"),
                      Text("result: ${item[2]}"),
                    ]
                  )
              ],
            ));
          }
          return Container();
        },
      ),
    );
  }
}
