import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_learning/ui/accounts/account_repository.dart';
import 'package:manage_learning/ui/accounts/create_account_state.dart';
import 'package:manage_learning/ui/accounts/create_accout_bloc.dart';
import 'package:provider/provider.dart';

class CreateAccount extends StatefulWidget {
  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final TextEditingController _usernameController = TextEditingController();
  String _generatedPassword = '';
  late CreateAccountCubit _createAccountCubit;

  @override
  void initState() {
    super.initState();
    _createAccountCubit = CreateAccountCubit(
      Provider.of<AccountRepository>(context, listen: false),
    );
    _generatedPassword = _createAccountCubit.generateRandomPassword();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _createAccountCubit,
      child: BlocConsumer<CreateAccountCubit, CreateAccountState>(
        listener: (context, state) {
          if (state is CreateAccountSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    'Account created for ${state.email} with password ${state.password}')));
          } else if (state is CreateAccountError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Failed to create account: ${state.message}')));
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: const Text('Create Account')),
            body: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 600) {
                    return _buildWideContainers(context, state);
                  } else {
                    return _buildNarrowContainer(context, state);
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, CreateAccountState state) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text('Generated Password: $_generatedPassword'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: state is CreateAccountLoading
                  ? null
                  : () => context.read<CreateAccountCubit>().createAccount(
                      _usernameController.text, _generatedPassword),
              child: state is CreateAccountLoading
                  ? const CircularProgressIndicator()
                  : const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideContainers(BuildContext context, CreateAccountState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          flex: 1,
          child: Container(),
        ),
        Expanded(
          flex: 2,
          child: _buildCard(context, state),
        ),
        Expanded(
          flex: 1,
          child: Container(),
        ),
      ],
    );
  }

  Widget _buildNarrowContainer(BuildContext context, CreateAccountState state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _buildCard(context, state),
    );
  }

  Widget _buildCard(BuildContext context, CreateAccountState state) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _usernameController,
              enabled: state is! CreateAccountLoading,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text('Generated Password: $_generatedPassword'),
            const SizedBox(height: 16),
            if (state is CreateAccountLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed:
                    state is CreateAccountLoading ? null : _createAccount,
                child: const Text('Create Account'),
              ),
            if (state is CreateAccountError)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  state.message,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _createAccount() {
    _createAccountCubit.createAccount(
        _usernameController.text, _generatedPassword);
  }
}
