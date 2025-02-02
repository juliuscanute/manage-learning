import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_learning/ui/accounts/account_repository.dart';
import 'package:manage_learning/ui/accounts/create_account_state.dart';
import 'package:manage_learning/ui/accounts/create_accout_bloc.dart';
import 'package:provider/provider.dart';

class ViewAccounts extends StatefulWidget {
  @override
  _ViewAccountsState createState() => _ViewAccountsState();
}

class _ViewAccountsState extends State<ViewAccounts> {
  late CreateAccountCubit _createAccountCubit;

  @override
  void initState() {
    super.initState();
    _createAccountCubit = CreateAccountCubit(
      Provider.of<AccountRepository>(context, listen: false),
    );
    _createAccountCubit.loadUsers();
  }

  @override
  void dispose() {
    _createAccountCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _createAccountCubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('View Accounts'),
        ),
        body: Center(
          child: BlocBuilder<CreateAccountCubit, CreateAccountState>(
            builder: (context, state) {
              if (state is CreateAccountLoading) {
                return const CircularProgressIndicator();
              } else if (state is UsersLoaded) {
                final accounts = state.users;

                if (accounts.isEmpty) {
                  return const Text('There are no accounts.');
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 600) {
                      // Large screen layout
                      return _buildWideContainers(accounts);
                    } else {
                      // Mobile layout
                      return _buildNarrowContainer(accounts);
                    }
                  },
                );
              } else {
                return const Text('Failed to load accounts.');
              }
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).pushNamed('/create-account');
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildWideContainers(List<Map<String, dynamic>> accounts) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 3,
      ),
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final account = accounts[index];
        return _buildAccountCard(account);
      },
    );
  }

  Widget _buildNarrowContainer(List<Map<String, dynamic>> accounts) {
    return ListView.builder(
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final account = accounts[index];
        return _buildAccountCard(account);
      },
    );
  }

  Widget _buildAccountCard(Map<String, dynamic> account) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(account['email']),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reset Password IconButton
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.blue),
              onPressed: () async {
                // Generate a new password using the cubit method.
                final newPassword =
                    _createAccountCubit.generateRandomPassword();
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Reset Password"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Do you want to reset the password to:"),
                        const SizedBox(height: 8),
                        SelectableText(
                          newPassword,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: newPassword));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Password copied to clipboard')),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text("Copy"),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Confirm"),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  _createAccountCubit.resetAccountPassword(
                      account['uid'], newPassword);
                }
              },
            ),
            // Delete IconButton
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Delete Account"),
                    content: const Text(
                        "Are you sure you want to delete this account?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Delete"),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  _createAccountCubit.deleteAccount(account['uid']);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
