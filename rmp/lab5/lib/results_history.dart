import 'package:get_storage/get_storage.dart';

final box = GetStorage('results');

List<List<int>> getResults() {
  return box.read<List<List<int>>>('resultsList') ?? [];
}

void addNewResults(int a, int b, int result) {
  List<List<int>> resultsList = getResults();
  resultsList.insert(0, [a, b, result]);
  box.write('resultsList', resultsList);
}

void clearResults() {
  List<List<int>> resultsList = [];
  box.write('resultsList', resultsList);
}
