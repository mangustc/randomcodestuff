import 'package:get_storage/get_storage.dart';

final box = GetStorage('results');
final parameterName = 'resultsList';
final List<List<int>> emptyArray = [];

List<List<int>> getResults() {
  final rawList = box.read<List<dynamic>>(parameterName);
  if (rawList == null) {
    return emptyArray;
  }
  return rawList.map((e) => List<int>.from(e as List<dynamic>)).toList();
}

void addNewResults(int a, int b, int result) {
  List<List<int>> resultsList = getResults();
  resultsList.insert(0, [a, b, result]);
  box.write(parameterName, resultsList);
}

void clearResults() {
  box.write(parameterName, emptyArray);
}
