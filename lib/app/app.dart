import 'package:flutter/material.dart';
import 'package:labelwise/features/scanner/presentation/screens/home_screen.dart';

class LabelWiseApp extends StatelessWidget {
  const LabelWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'LabelWise', home: HomeScreen());
  }
}
