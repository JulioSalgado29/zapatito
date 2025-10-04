import 'package:flutter/material.dart';
import 'package:zapatito/design-widgets/desing_widgets.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Designwidgets().tittleCustom("Bienvenido a Zapatito"),
                Designwidgets().loginButton("Iniciar Sesión", Colors.white, const Color(0xff3a086c)),
                Designwidgets().singupButton("Registrarte", const Color(0xff3a086c), Colors.white),
                Container(
                  padding: const EdgeInsets.only(top: 25),
                  width: double.infinity,
                  child: MaterialButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/home');
                    },
                    color: const Color.fromARGB(255, 33, 47, 243),
                    textColor: Colors.white,
                    child: const Text(
                      'HOME',
                    ),
                  )
                )
              ],
            ),
          )
        )
      )
    );
  }
}