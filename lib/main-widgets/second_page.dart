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
          'Segunda Pagina',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Georgia'),
        ),
      ),
      body: Center(
          child: MaterialButton(
        onPressed: () {
          Navigator.pop(context);
        },
        color: const Color.fromARGB(255, 33, 47, 243),
        textColor: Colors.white,
        child: const Text(
          'Pagina 1',
        ),
      )),
    );
  }
}
