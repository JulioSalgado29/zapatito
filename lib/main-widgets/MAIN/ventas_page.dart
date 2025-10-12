import 'package:flutter/material.dart';
import 'package:zapatito/components/widgets.dart';

class VentasPage extends StatelessWidget {
  const VentasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Designwidgets().appBarMain("Ventas")
    );
  }
}
