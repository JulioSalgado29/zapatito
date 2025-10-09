import 'package:auth_buttons/auth_buttons.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zapatito/auth/service/google_auth.dart';
import 'package:zapatito/components/SplashScreen/splash_screen_copy.dart';
import 'package:zapatito/main-widgets/home_page.dart';

class Designwidgets {

  LinearGradient linearGradientMain(BuildContext context) {
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xff5b16c2),
        Color(0xff5b16c2),
      ],
    );
  }
  
  RichText tittleCustom(String text) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        text: text,
        style: GoogleFonts.mouseMemoirs(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: const Color(0xff3a086c),
        ),/*
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color:Color(0xff3a086c),
        ),*/
      ),
    );
  }

  Widget singupLabel(){
    return Container(
      margin: const EdgeInsets.only(top: 30, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            '¿No tienes una cuenta?',
            style: TextStyle(
              color: Color(0xff3a086c),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () => print('Registrarse Presionado'),
            child: const Text(
              'Regístrate',
              style: TextStyle(
                color: Color(0xff3a086c),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget googleButton(BuildContext context) {
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
          print(silentResult);
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

  Widget forgottenPassword() {
    return Container(
      padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => print('¿Has olvidado tu contraseña?'),
        child: const Text(
          '¿Has olvidado tu contraseña?',
          style: TextStyle(
            color: Color(0xff3a086c),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget divider(){
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: const Row(
        children: <Widget>[
          SizedBox(
            width: 20,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Divider(
                thickness: 1,
              ),
            ),
          ),
          Text('O'),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Divider(
                thickness: 1,
              ),
            ),
          ),
          SizedBox(
            width: 20,
          ),
        ],
      ),
    );
  }
  
  Widget loginButton(String text, Color color, Color textColor, BuildContext context, String routeName) {
    return Container(
      padding: const EdgeInsets.only(top: 50.0, bottom: 25),
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(
          elevation: 5.0,
          backgroundColor: color,
          padding: const EdgeInsets.all(15.0),
          shape: RoundedRectangleBorder(
            side: const BorderSide(
              color: Colors.black, // Set your desired border color here
              width: 2, // Optional: Set the border width
            ),
            borderRadius: BorderRadius.circular(5.0),
          ),
          iconColor: Colors.white,
        ),
        onPressed: () => Navigator.pushNamed(context, routeName),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        )
      ),
    );
  }

  Widget singupButton(String text, Color color, Color textColor) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(
          elevation: 5.0,
          backgroundColor: color,
          padding: const EdgeInsets.all(15.0),
          shape: RoundedRectangleBorder(
            side: const BorderSide(
              color: Colors.black, // Set your desired border color here
              width: 2, // Optional: Set the border width
            ),
            borderRadius: BorderRadius.circular(5.0),
          ),
          iconColor: Colors.white,
        ),
        onPressed: () => print('Signup Presionado'),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        )
      ),
    );
  }
}