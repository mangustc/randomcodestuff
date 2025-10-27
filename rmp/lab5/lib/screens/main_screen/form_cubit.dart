import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lab5/results_history.dart';
import 'dart:math';
import 'package:lab5/screens/main_screen/form_cubit_state.dart';

class FormCubit extends Cubit<FormCubitState> {
  FormCubit() : super(FormCubitStateFormPage(a: "", aErrorMessage: null, b: "", bErrorMessage: null, sogl: false));

  void changeA(String newValue) {
    if (state is FormCubitStateFormPage) {
      final currentState = state as FormCubitStateFormPage;
      emit(FormCubitStateFormPage(a: newValue, aErrorMessage: null, b: currentState.b, bErrorMessage: currentState.bErrorMessage, sogl: currentState.sogl));
    }
  }
  void changeB(String newValue) {
    if (state is FormCubitStateFormPage) {
      final currentState = state as FormCubitStateFormPage;
      emit(FormCubitStateFormPage(a: currentState.a, aErrorMessage: currentState.aErrorMessage, b: newValue, bErrorMessage: null, sogl: currentState.sogl));
    }
  }
  void changeSogl(bool newValue) {
    if (state is FormCubitStateFormPage) {
      final currentState = state as FormCubitStateFormPage;
      emit(FormCubitStateFormPage(a: currentState.a, aErrorMessage: currentState.aErrorMessage, b: currentState.b, bErrorMessage: currentState.bErrorMessage, sogl: newValue));
    }
  }
  void calculate() {
    if (state is FormCubitStateFormPage) {
      String? aMsg;
      String? bMsg;
      final currentState = state as FormCubitStateFormPage;
      if (!currentState.sogl) {
        return;
      }

      final aInt = int.tryParse(currentState.a);
      if (aInt == null) {
        aMsg = "Enter a valid integer";
      }
      if (currentState.a.isEmpty) {
        aMsg = "Enter a value";
      }

      final bInt = int.tryParse(currentState.b);
      if (bInt == null) {
        bMsg = "Enter a valid integer";
      }
      if (currentState.b.isEmpty) {
        bMsg = "Enter a value";
      }


      if (aInt == null || bInt == null) {
        emit(FormCubitStateFormPage(
          a: currentState.a,
          aErrorMessage: aMsg,
          b: currentState.b,
          bErrorMessage: bMsg,
          sogl: currentState.sogl,
        ));
        return;
      }
      final result = pow(aInt + bInt, 3).toInt();

      addNewResults(aInt, bInt, result);
      emit(FormCubitStateResultPage(result: result));
    }
  }
  void goBack() {
    if (state is FormCubitStateResultPage) {
      emit(FormCubitStateFormPage(a: "", aErrorMessage: null, b: "", bErrorMessage: null, sogl: false));
    }
  }
}
