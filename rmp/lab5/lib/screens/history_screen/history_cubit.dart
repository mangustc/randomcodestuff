import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lab5/results_history.dart';
import 'package:lab5/screens/history_screen/history_cubit_state.dart';

class HistoryCubit extends Cubit<HistoryCubitState> {
  HistoryCubit() : super(HistoryCubitStateHistoryPage(resultList: getResults()));
  // void loadData() {
  //   if (state is HistoryCubitStateHistoryPage) {
  //     emit(HistoryCubitStateHistoryPage(resultList: getResults()));
  //   }
  // }
}
