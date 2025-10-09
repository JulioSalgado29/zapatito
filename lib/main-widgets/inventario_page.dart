import 'package:flutter/material.dart';
import 'package:zapatito/components/widgets.dart';

class SecondPage extends StatelessWidget {
  const SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Designwidgets().appBarMain("Inventario"),
    );
  }
}
