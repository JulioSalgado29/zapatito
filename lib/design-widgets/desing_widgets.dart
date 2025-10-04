import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Designwidgets {
  
  RichText tittleCustom(String text) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        text: text,
        style: GoogleFonts.mouseMemoirs(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: const Color(0xff3a086c),
        ),
      ),
    );
  }

  Widget loginButton(String text, Color color, Color textColor) {
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
        onPressed: () => print('Login Presionado'),
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