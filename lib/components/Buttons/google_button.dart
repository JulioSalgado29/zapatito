import 'package:auth_buttons/auth_buttons.dart';
import 'package:flutter/material.dart';
import 'package:zapatito/auth/service/google_auth.dart';
import 'package:zapatito/components/SplashScreen/splash_screen.dart';
import 'package:zapatito/main-widgets/MAIN/home_page.dart';

class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      child: GoogleAuthButton(
        onPressed: () async {
          print('Google button pressed');

          // Mostrar splash mientras se autentica
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const SplashScreen02(),
          );

          // Intentar iniciar sesión de forma silenciosa primero
          final silentResult = await GoogleAuthService().trySilentSignIn();

          if (silentResult != null) {
            print('Sesión silenciosa exitosa');
            print(silentResult);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
            return;
          }

          // Si no hubo sesión silenciosa, iniciar sesión manual
          final result = await GoogleAuthService().signInWithGoogle();

          if (result != null) {
            print('Usuario autenticado con Google');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          } else {
            Navigator.of(context).pop(); // Cierra el splash
            print('Error o usuario canceló la autenticación');
          }
        },
        text: 'Iniciar sesión con Google',
        style: const AuthButtonStyle(
          borderRadius: 5.0,
          buttonColor: Colors.white,
        ),
      ),
    );
  }
}