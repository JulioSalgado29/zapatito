import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zapatito'),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            MaterialButton(
              onPressed: () {
                Navigator.pushNamed(context, '/splash_screen', arguments: '/first_page',);
              },
              color: const Color.fromARGB(255, 33, 47, 243),
              textColor: Colors.white,
              child: const Text(
                'Pagina 1',
                ),
              ),
            MaterialButton(
              onPressed: () {
                Navigator.pushNamed(context, '/splash_screen', arguments: '/second_page',);
              },
              color: const Color.fromARGB(255, 33, 47, 243),
              textColor: Colors.white,
              child: const Text(
                'Pagina 2',
              ),
            ),
          ]
        )
      ),
    );
  }
}
