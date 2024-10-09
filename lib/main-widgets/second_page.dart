import 'package:flutter/material.dart';

class SecondRoute extends StatelessWidget {
  const SecondRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff5b16c2),
        foregroundColor: Colors.white,
        title: const Text(
          'Opcion 1',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Georgia'),
        ),
      ),
    );
  }
}
