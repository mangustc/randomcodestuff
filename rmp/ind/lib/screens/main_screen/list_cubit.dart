import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ind/structures.dart';

class ListCubitState {
  final List<Person> personList;
  final List<Person> countryList;
  final List<Person> personFullList;

  ListCubitState({required this.personList, required this.countryList, required this.personFullList});
}

class ListCubit extends Cubit<ListCubitState> {
  ListCubit() : super(ListCubitState(personList: [], countryList: [], personFullList: []));

  void readDB() {

  }

  void updateSearch(PersonFilter filters) {
    // emit(ListCubitStateListPage(personList: [], wantedByList: [], nationalityList: []));
  }
}
