import 'package:flutter/material.dart';

class FirstRoute extends StatelessWidget {
  const FirstRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff5b16c2),
        foregroundColor: Colors.white,
        title: const Text(
          'Home',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Georgia'),
        ),
      ),
      body: Center(
          child: MaterialButton(
            onPressed: () {
            Navigator.pushNamed(context, '/second_page');
          },
          color: const Color.fromARGB(255, 33, 47, 243),
          textColor: Colors.white,
          child: const Text(
          'Opcion 1',
          ),
        )
      ),
    );
  }
}
