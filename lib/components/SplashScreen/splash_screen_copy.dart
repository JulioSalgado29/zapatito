import 'package:flutter/material.dart';

class SplashScreen02 extends StatelessWidget {
  const SplashScreen02({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fondo negro
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  Image.asset(
                    'lib/assets/ic_launcher.png',
                    height: 60,
                    width: 60,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Cargando...",
              style: TextStyle(color: Colors.white),
            )
          ],
        ),
      ),
    );
  }
}