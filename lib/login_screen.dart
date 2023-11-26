import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:manage_learning/page_route_animation.dart';
import 'package:manage_learning/welcome_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Determine screen size
    var screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(title: const Text('John Louis Academy for learners')),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: 400), // Max width for form
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isLoading ? null : () => _login(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(200,
                          50), // Set a nice width and height for the button
                      padding: EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10), // Adjust padding
                    ),
                    child: isLoading
                        ? SizedBox(
                            height: 24.0, // Smaller than the button's height
                            width: 24.0, // Smaller than the button's width
                            child: CircularProgressIndicator(
                              strokeWidth:
                                  3.0, // Adjust the spinning line width
                              color: Colors.white, // Spinner color
                            ),
                          )
                        : const Text('Login',
                            style: TextStyle(fontSize: 16)), // Text styling
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login(BuildContext context) async {
    // Implement login logic
    setState(() {
      isLoading = true; // Start loading
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // On successful login
      if (mounted) {
        Navigator.of(context).pushReplacement(
          NoAnimationPageRoute(page: const WelcomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        _showToast(context, 'Login Failed: ${e.toString()}');
      }
    } finally {
      setState(() {
        isLoading = false; // Stop loading on success/error
      });
    }
  }

  void _showToast(BuildContext context, String message) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
            label: 'OK', onPressed: scaffold.hideCurrentSnackBar),
      ),
    );
  }
}
