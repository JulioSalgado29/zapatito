import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CalzadoForm extends StatefulWidget {
  final String? firstName;
  final bool isOnline;
  final DocumentSnapshot? doc;

  const CalzadoForm({
    super.key,
    this.firstName,
    required this.isOnline,
    this.doc,
  });

  @override
  State<CalzadoForm> createState() => _CalzadoFormState();
}

class _CalzadoFormState extends State<CalzadoForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();

  String? _selectedTipoCalzadoId;
  bool get isEditing => widget.doc != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final data = widget.doc!.data() as Map<String, dynamic>;
      _nombreController.text = data['nombre'] ?? '';
      _precioController.text =
          (data['precio_real'] ?? 0.0).toStringAsFixed(2);
      _selectedTipoCalzadoId = data['tipo_calzado_id'];
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
    if (_selectedTipoCalzadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un tipo de calzado')),
      );
      return;
    }

    final precioText = _precioController.text.replaceAll("S/", "").trim();
    final precio = double.tryParse(precioText) ?? 0.0;

    final data = {
      'nombre': _nombreController.text.trim(),
      'precio_real': double.parse(precio.toStringAsFixed(2)),
      'usuario_creacion': widget.firstName,
      'fecha_creacion': FieldValue.serverTimestamp(),
      'tipo_calzado_id': _selectedTipoCalzadoId,
      'activo': true,
    };

    try {
      if (isEditing) {
        await FirebaseFirestore.instance
            .collection('calzado')
            .doc(widget.doc!.id)
            .update(data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Calzado actualizado correctamente ✏️'),
          ),
        );
      } else {
        await FirebaseFirestore.instance.collection('calzado').add(data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Calzado agregado correctamente ✅'),
          ),
        );
      }
      if (mounted) Navigator.pop(context);
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
        physics: const BouncingScrollPhysics(),
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

              // Nombre
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingrese un nombre' : null,
              ),

              // Precio
              TextFormField(
                controller: _precioController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}$')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Precio real',
                  prefixText: 'S/ ',
                ),
                validator: validarPrecio,
              ),

              const SizedBox(height: 16),

              // Dropdown tipo calzado
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('tipo_calzado')
                    .where('activo', isEqualTo: true)
                    .orderBy('fecha_creacion', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text('No hay tipos de calzado disponibles.');
                  }

                  final tipos = snapshot.data!.docs;

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Calzado',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedTipoCalzadoId,
                    items: tipos.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final icono = data['icono'] ?? '';
                      final nombre = data['nombre'] ?? '';

                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (icono.toString().isNotEmpty &&
                                (icono.toString().endsWith('.png') ||
                                    icono.toString().endsWith('.jpg')))
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Image.asset(
                                  icono,
                                  width: 28,
                                  height: 28,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.image,
                                    size: 24,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  icono.toString(),
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                            Flexible(
                              child: Text(
                                nombre,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedTipoCalzadoId = val),
                    validator: (v) =>
                        v == null ? 'Seleccione un tipo de calzado' : null,
                  );
                },
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _guardarCalzado,
                  icon: Icon(isEditing ? Icons.save_as : Icons.save),
                  label: Text(isEditing
                      ? 'Actualizar Calzado'
                      : 'Guardar Calzado'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
