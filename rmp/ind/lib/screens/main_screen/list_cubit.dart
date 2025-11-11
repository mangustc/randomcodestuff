import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ind/db.dart';
import 'package:ind/structures.dart';


class ListCubitState {
  final List<PersonFull> personFullList;
  final List<Country> countryList;

  ListCubitState({required this.personFullList, required this.countryList});
}

class ListCubit extends Cubit<ListCubitState> {
  ListCubit() : super(ListCubitState(personFullList: [], countryList: []));

  Future<void> updateSearch(PersonFilter filter) async {
    var countryList = await DBProvider.db.getCountryList();
    var personFullList = await DBProvider.db.getPersonFullList(filter);
    emit(ListCubitState(personFullList: personFullList, countryList: countryList));
  }
}
