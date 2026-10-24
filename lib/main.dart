import 'package:flutter/material.dart';

import 'doors/door_lab_screen.dart';

void main() => runApp(const CurreDoorSpikeApp());

class CurreDoorSpikeApp extends StatelessWidget {
  const CurreDoorSpikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Curre Door Lab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE85F2E)),
        useMaterial3: true,
      ),
      home: const DoorLabScreen(),
    );
  }
}
