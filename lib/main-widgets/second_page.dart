import 'package:flutter/material.dart';

class SecondPage extends StatelessWidget {
  const SecondPage({super.key});

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
            Navigator.pushNamed(context, '/first_page');
          },
          color: const Color.fromARGB(255, 33, 47, 243),
          textColor: Colors.white,
          child: const Text(
          'Pagina 1',
          )
        )
      ),
    );
  }
}
