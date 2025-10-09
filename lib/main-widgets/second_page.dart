import 'package:flutter/material.dart';
import 'package:zapatito/components/widgets.dart';

class SecondPage extends StatelessWidget {
  const SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Designwidgets().appBarMain("Segunda Página"),
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
