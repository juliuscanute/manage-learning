import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_learning/ui/accounts/account_repository.dart';
import 'package:manage_learning/ui/accounts/create_account_state.dart';

class CreateAccountCubit extends Cubit<CreateAccountState> {
  final AccountRepository repository;

  CreateAccountCubit(this.repository) : super(CreateAccountInitial());

  String generateRandomPassword({int length = 12}) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  Future<void> createAccount(String email, String password) async {
    try {
      emit(CreateAccountLoading());
      await repository.createTeacherAccount(email, password);
      emit(CreateAccountSuccess(email, password));
    } catch (e) {
      emit(CreateAccountError(e.toString()));
    }
  }

  Future<void> loadUsers() async {
    try {
      emit(CreateAccountLoading());
      final users = await repository.loadUsers();
      emit(UsersLoaded(users));
    } catch (e) {
      emit(CreateAccountError(e.toString()));
    }
  }

  Future<void> deleteAccount(String uid) async {
    try {
      emit(CreateAccountLoading());
      await repository.deleteTeacherAccount(uid);
      emit(DeleteAccountSuccess());
      await loadUsers();
    } catch (e) {
      emit(DeleteAccountError(e.toString()));
    }
  }

  Future<void> resetAccountPassword(String uid, String newPassword) async {
    try {
      emit(CreateAccountLoading());
      await repository.resetUserPassword(uid, newPassword);
      emit(ResetPasswordSuccess(uid));
      await loadUsers();
    } catch (e) {
      emit(ResetPasswordError(e.toString()));
    }
  }
}
