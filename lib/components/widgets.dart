import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Designwidgets {

  LinearGradient linearGradientMain(BuildContext context) {
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xff3a086c),
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

  Widget forgottenPassword() {
    return Container(
      padding: const EdgeInsets.only(bottom: 20.0),
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
      margin: const EdgeInsets.symmetric(vertical: 5),
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
  
}