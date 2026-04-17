import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zapatito/components/SplashScreen/splash_screen.dart';
import 'package:zapatito/components/widgets.dart';

class DuenoMuestraForm extends StatefulWidget {
  final String? firstName;
  final String? emailUser;
  final String? inventarioId;

  // 🔹 Parámetros para edición
  final String? duenoId;
  final String? nombreInicial;

  const DuenoMuestraForm({
    super.key,
    this.firstName,
    this.emailUser,
    this.inventarioId,
    this.duenoId,
    this.nombreInicial,
  });

  @override
  State<DuenoMuestraForm> createState() => _DuenoMuestraFormState();
}

class _DuenoMuestraFormState extends State<DuenoMuestraForm> {
  final TextEditingController _nombreController = TextEditingController();
  bool _estaEditando = false;

  @override
  void initState() {
    super.initState();
    // 🔹 Si recibimos un ID, significa que estamos editando
    if (widget.duenoId != null) {
      _estaEditando = true;
      _nombreController.text = widget.nombreInicial ?? '';
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  // 🔹 Validación: El nombre no puede estar vacío
  bool get _puedeGuardar => _nombreController.text.trim().isNotEmpty;

  void _mostrarSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _guardarDueno() async {
  if (!_puedeGuardar) {
    _mostrarSnack('Por favor, ingrese un nombre.');
    return;
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const SplashScreen02(),
  );

  try {
    final db = FirebaseFirestore.instance.collection('dueno_muestra');

    final Map<String, dynamic> data = {
      'nombre': _nombreController.text.trim(),
      'usuario_edicion': widget.firstName ?? 'anon',
      'fecha_modificacion': Timestamp.now(),
    };

    if (_estaEditando) {
      await db.doc(widget.duenoId).update(data);
    } else {
      // 🔹 Al insertar nuevo, añadimos estado: true
      data['estado'] = true; 
      data['fecha_creacion'] = Timestamp.now(); // Recomendado tenerlo
      await db.add(data);
    }

    if (Navigator.canPop(context)) Navigator.pop(context); 
    _mostrarSnack(_estaEditando ? 'Actualizado' : 'Registrado');
    Navigator.pop(context); 
  } catch (e) {
    if (Navigator.canPop(context)) Navigator.pop(context);
    _mostrarSnack('Error: $e');
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Designwidgets()
          .appBarMain(_estaEditando ? 'Editar Dueño' : 'Nuevo Dueño'),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Datos del Propietario',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nombreController,
              textCapitalization:
                  TextCapitalization.words, // 🔹 Primera letra en mayúscula
              decoration: const InputDecoration(
                labelText: 'Nombre Completo',
                hintText: 'Ej: Juan Pérez',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_add_alt_1),
              ),
              onChanged: (v) =>
                  setState(() {}), // Refresca el botón al escribir
            ),
            const SizedBox(height: 16),
            SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _guardarDueno,
                    icon: Icon(_estaEditando ? Icons.save_as : Icons.save),
                    label: Text(
                        _estaEditando ? 'Actualizar Dueño' : 'Guardar Dueño'),
                  ),
                ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
