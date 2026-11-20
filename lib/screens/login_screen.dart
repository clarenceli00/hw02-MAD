import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenService();
}

class _LoginScreenService extends State<LoginScreen> {
  
  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Center(
        child: Form(child: Text("asdf"),)
      )
    );
  }
}
