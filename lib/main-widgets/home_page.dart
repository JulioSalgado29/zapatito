import 'package:flutter/material.dart';
import 'package:zapatito/components/widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Designwidgets().appBarMain("Principal"),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            MaterialButton(
              onPressed: () {
                Navigator.pushNamed(context, '/ventas_page');
              },
              color: const Color.fromARGB(255, 33, 47, 243),
              textColor: Colors.white,
              child: const Text(
                'Ventas',
                ),
              ),
            MaterialButton(
              onPressed: () {
                Navigator.pushNamed(context, '/inventario_page');
              },
              color: const Color.fromARGB(255, 33, 47, 243),
              textColor: Colors.white,
              child: const Text(
                'Inventario',
              ),
            ),
          ]
        )
      ),
    );
  }
}
