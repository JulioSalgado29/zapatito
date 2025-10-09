import 'package:flutter/material.dart';
import 'package:zapatito/components/widgets.dart';

class FirstPage extends StatelessWidget {
  const FirstPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Designwidgets().appBarMain("Ventas"),
      body: Center(
        child: MaterialButton(
          onPressed: () {
            Navigator.pushNamed(context, '/inventario_page');
          },
          color: const Color.fromARGB(255, 33, 47, 243),
          textColor: Colors.white,
          child: const Text(
          'Pagina 2',
          )
        )
      )
    );
  }
}
