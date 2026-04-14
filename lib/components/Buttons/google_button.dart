import 'package:auth_buttons/auth_buttons.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zapatito/auth/service/google_auth.dart';
import 'package:zapatito/components/SplashScreen/splash_screen.dart';
import 'package:zapatito/main-widgets/MAIN/home_page.dart';
import 'package:zapatito/services/local_storage.dart';

class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key});

  // Función modificada para invocar tu LocalStorageService
  Future<void> _saveUserLog() async {
    try {
      // Invocación tal cual como me mostraste
      final data = await LocalStorageService.getUserData();
      final email = data['email'];

      if (email != null) {
        await FirebaseFirestore.instance.collection('sesion_google_log').add({
          'email': email,
          'name': data['name'] ?? 'Usuario sin nombre',
          'fecha_ingreso': FieldValue.serverTimestamp(),
          'plataforma': 'Google',
        });
        print('Log registrado exitosamente en Firestore');
      }
    } catch (e) {
      print('Error al guardar el log en Firestore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      child: GoogleAuthButton(
        onPressed: () async {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const SplashScreen02(),
          );

          // 1. Intento Silencioso
          final silentResult = await GoogleAuthService().trySilentSignIn();

          if (silentResult != null) {
            // Esperamos a que se guarde el log antes de navegar
            await _saveUserLog(); 
            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            }
            return;
          }

          // 2. Intento Manual
          final result = await GoogleAuthService().signInWithGoogle();

          if (result != null) {
            // Esperamos a que se guarde el log antes de navegar
            await _saveUserLog(); 
            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            }
          } else {
            if (context.mounted) Navigator.of(context).pop();
            print('Error o usuario canceló');
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