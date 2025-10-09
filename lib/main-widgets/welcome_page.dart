import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:zapatito/components/Buttons/login_button.dart';
import 'package:zapatito/components/Buttons/singup_button.dart';
import 'package:zapatito/components/SplashScreen/splash_screen.dart';
import 'package:zapatito/components/widgets.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: FutureBuilder(
            future: _initialization,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                print('FIREBASE INIT. ERROR');
                return const Center(
                  child: Text("Error al inicializar Firebase"),
                );
              } else if (snapshot.connectionState == ConnectionState.done) {
                print('FIREBASE INIT. DONE');
                //return const SplashScreen02();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Designwidgets().tittleCustom("Bienvenido a Zapatito"),
                      const LoginButton(
                        text: "Iniciar Sesión",
                        color: Colors.white,
                        textColor: Color(0xff3a086c),
                        routeName: '/login',
                      ),
                      const SingupButton(
                          text: "Registrarte",
                          color: Color(0xff3a086c),
                          textColor: Colors.white),
                      /*Container(
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
                      )*/
                    ],
                  ),
                );
              }
              print('FIREBASE INIT. LOADING');
              return const SplashScreen02();
            }));
  }
}
