import 'package:flutter/material.dart';
import 'package:zapatito/components/Buttons/back_button.dart';
import 'package:zapatito/components/Fields/field_form.dart';
import 'package:zapatito/components/Shapes/container_shape.dart';
import 'package:zapatito/components/widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            const ContainerShape01(),
            Positioned(top: height * .025, child: const BackButton01()),
            Container(
              height: double.infinity,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: height * .15),
                    child: Designwidgets().tittleCustom("Inicio de Sesión"),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: height * .05),
                    child: _emailPasswordWidget()
                  ),
                  Designwidgets().loginButton("Iniciar Sesión", const Color(0xff3a086c), Colors.white, context, '/home'),
                  Designwidgets().forgottenPassword(),
                  Designwidgets().divider(),
                  Designwidgets().googleButton(),
                  Designwidgets().singupLabel(),
                ],
              )
            )
          ],
        ),
      )
    );
  }

  Widget _emailPasswordWidget() {
    return const Column(
      children: <Widget>[
        FieldForm(tittle: "Email", isPassword: false),
        FieldForm(tittle: "Contraseña", isPassword: true)
      ]
    );
  }
} 