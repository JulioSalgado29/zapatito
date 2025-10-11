import 'package:flutter/material.dart';
import 'package:zapatito/components/widgets.dart';

class FirstPage extends StatelessWidget {
  const FirstPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Designwidgets().appBarMain("Ventas")
    );
  }
}
