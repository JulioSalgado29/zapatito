import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CalzadoForm extends StatefulWidget {
  final String? firstName;
  final bool isOnline;
  final DocumentSnapshot? doc;

  const CalzadoForm({super.key, this.firstName, required this.isOnline, this.doc});

  @override
  State<CalzadoForm> createState() => _CalzadoFormState();
}

class _CalzadoFormState extends State<CalzadoForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  bool get isEditing => widget.doc != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final data = widget.doc!.data() as Map<String, dynamic>;
      _nombreController.text = data['nombre'] ?? '';
      _precioController.text = (data['precio_real'] ?? 0.0).toStringAsFixed(2);
    }
  }

  String? validarPrecio(String? valor) {
    if (valor == null || valor.isEmpty) return 'Ingrese un precio';
    final precioText = valor.replaceAll("S/", "").trim();
    final precio = double.tryParse(precioText);
    if (precio == null) return 'Ingrese solo números válidos';
    if (precio > 150) return 'No puede superar el precio de S/ 150';
    return null;
  }

  Future<void> _guardarCalzado() async {
    if (!_formKey.currentState!.validate()) return;

    final precioText = _precioController.text.replaceAll("S/", "").trim();
    final precio = double.tryParse(precioText) ?? 0.0;

    final data = {
      'nombre': _nombreController.text,
      'precio_real': double.parse(precio.toStringAsFixed(2)),
      'usuario_creacion': widget.firstName,
      'fecha_creacion': FieldValue.serverTimestamp(),
      'activo': true,
    };

    try {
      if (isEditing) {
        await FirebaseFirestore.instance.collection('calzado').doc(widget.doc!.id).update(data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Calzado actualizado correctamente ✏️')),
        );
      } else {
        await FirebaseFirestore.instance.collection('calzado').add(data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Calzado agregado correctamente ✅')),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 20).copyWith(top: 24, bottom: 40),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                isEditing ? "Editar Calzado" : "Agregar Calzado",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => v == null || v.isEmpty ? 'Ingrese un nombre' : null,
              ),
              TextFormField(
                controller: _precioController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}$')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Precio real',
                  prefixText: 'S/ ',
                ),
                validator: validarPrecio,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _guardarCalzado,
                  icon: Icon(isEditing ? Icons.save_as : Icons.save),
                  label: Text(isEditing ? 'Actualizar Calzado' : 'Guardar Calzado'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
