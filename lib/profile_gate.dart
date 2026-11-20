import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileGate extends StatefulWidget {
  final User user;

  const ProfileGate({super.key, required this.user});
  @override
  State<ProfileGate> createState() => _ProfileGateService();
}

class _ProfileGateService extends State<ProfileGate> {
  @override
  Widget build(BuildContext context){
    return Scaffold();
  }
}