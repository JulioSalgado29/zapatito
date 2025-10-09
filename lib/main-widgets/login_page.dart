import 'package:flutter/material.dart';
import 'package:zapatito/components/Buttons/back_button.dart';
import 'package:zapatito/components/Buttons/google_button.dart';
import 'package:zapatito/components/Buttons/login_button.dart';
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
    final size = MediaQuery.of(context).size;
    final height = size.height;

    return Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            /// 👉 Contenido principal con scroll adaptable
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: height,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: height * 0.15),
                      Designwidgets().tittleCustom("Inicio de Sesión"),

                      SizedBox(height: height * 0.02),
                      _emailPasswordWidget(),

                      SizedBox(height: height * 0.025),
                      const LoginButton(
                        text: "Iniciar Sesión",
                        color: Color(0xff3a086c),
                        textColor: Colors.white,
                        routeName: '/home',
                      ),

                      const SizedBox(height: 8),
                      Designwidgets().forgottenPassword(),
                      Designwidgets().divider(),
                      const GoogleButton(),
                      Designwidgets().singupLabel(),
                    ],
                  ),
                ),
              ),
            ),
            const ContainerShape01(),
            /// 👉 Botón flotante sobre todo
            Positioned(
              top: height * 0.04,
              left: 10,
              child: const BackButton01(),
            ),
          ],
        ),
      );
  }

  Widget _emailPasswordWidget() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldForm(tittle: "Email", isPassword: false),
        SizedBox(height: 16),
        FieldForm(tittle: "Contraseña", isPassword: true),
      ],
    );
  }
}
