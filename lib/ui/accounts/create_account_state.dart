abstract class CreateAccountState {}

class CreateAccountInitial extends CreateAccountState {}

class CreateAccountLoading extends CreateAccountState {}

class CreateAccountSuccess extends CreateAccountState {
  final String email;
  final String password;
  CreateAccountSuccess(this.email, this.password);
}

class CreateAccountError extends CreateAccountState {
  final String message;
  CreateAccountError(this.message);
}

class UsersLoaded extends CreateAccountState {
  final List<Map<String, dynamic>> users;
  UsersLoaded(this.users);
}

class DeleteAccountSuccess extends CreateAccountState {}

class DeleteAccountError extends CreateAccountState {
  final String message;
  DeleteAccountError(this.message);
}

class ResetPasswordSuccess extends CreateAccountState {
  final String uid;
  ResetPasswordSuccess(this.uid);
}

class ResetPasswordError extends CreateAccountState {
  final String message;
  ResetPasswordError(this.message);
}
