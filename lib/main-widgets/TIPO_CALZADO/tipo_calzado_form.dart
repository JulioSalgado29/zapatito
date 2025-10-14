import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TipoCalzadoForm extends StatefulWidget {
  final String? firstName;
  final bool isOnline;
  final DocumentSnapshot? doc;

  const TipoCalzadoForm({
    super.key,
    this.firstName,
    required this.isOnline,
    this.doc,
  });

  @override
  State<TipoCalzadoForm> createState() => _TipoCalzadoFormState();
}

class _TipoCalzadoFormState extends State<TipoCalzadoForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  String? _iconoSeleccionado;

  bool get isEditing => widget.doc != null;

  // Lista de íconos disponibles (desde assets)
  final List<String> _iconos = [
    'lib/assets/calzados/botin.png',
    'lib/assets/calzados/escolar.png',
    'lib/assets/calzados/mocasin.png',
    'lib/assets/calzados/sandalia.png',
    'lib/assets/calzados/taco.png',
    'lib/assets/calzados/zapatilla.png',
  ];

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final data = widget.doc!.data() as Map<String, dynamic>;
      _nombreController.text = data['nombre'] ?? '';
      _iconoSeleccionado = data['icono']; // ruta guardada
    }
  }

  Future<void> _guardarTipoCalzado() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'nombre': _nombreController.text.trim(),
      'icono': _iconoSeleccionado,
      'usuario_creacion': widget.firstName,
      'fecha_creacion': FieldValue.serverTimestamp(),
      'activo': true,
    };

    try {
      if (isEditing) {
        await FirebaseFirestore.instance
            .collection('tipo_calzado')
            .doc(widget.doc!.id)
            .update(data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tipo de calzado actualizado ✏️')),
        );
      } else {
        await FirebaseFirestore.instance.collection('tipo_calzado').add(data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tipo de calzado agregado ✅')),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
                isEditing ? "Editar Tipo de Calzado" : "Agregar Tipo de Calzado",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => v == null || v.isEmpty ? 'Ingrese un nombre' : null,
              ),
              const SizedBox(height: 16),
              const Text(
                "Seleccionar ícono:",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _iconos.map((path) {
                  final isSelected = _iconoSeleccionado == path;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _iconoSeleccionado = path);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey.shade300,
                          width: isSelected ? 2.5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: isSelected
                            ? [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 5)]
                            : null,
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(
                        path,
                        width: 48,
                        height: 48,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _iconoSeleccionado == null
                      ? null
                      : _guardarTipoCalzado,
                  icon: Icon(isEditing ? Icons.save_as : Icons.save),
                  label: Text(isEditing
                      ? 'Actualizar Tipo de Calzado'
                      : 'Guardar Tipo de Calzado'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
