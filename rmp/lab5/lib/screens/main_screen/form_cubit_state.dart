abstract class FormCubitState {}

class FormCubitStateFormPage extends FormCubitState {
  final String a;
  final String? aErrorMessage;
  final String b;
  final String? bErrorMessage;
  final bool sogl;
  FormCubitStateFormPage({required this.a, required this.aErrorMessage, required this.b, required this.bErrorMessage, required this.sogl});
}

class FormCubitStateResultPage extends FormCubitState {
  final int result;
  FormCubitStateResultPage({required this.result});
}

