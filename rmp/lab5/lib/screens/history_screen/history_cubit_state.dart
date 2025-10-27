abstract class HistoryCubitState {}

class HistoryCubitStateHistoryPage extends HistoryCubitState {
  final List<List<int>> resultList;
  HistoryCubitStateHistoryPage({required this.resultList});
}
