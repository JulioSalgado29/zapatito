import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zapatito/components/widgets.dart';

class CalzadoFormPage extends StatefulWidget {
  final String? firstName;
  final bool isOnline;
  final DocumentSnapshot? doc;

  const CalzadoFormPage({
    super.key,
    this.firstName,
    required this.isOnline,
    this.doc,
  });

  @override
  State<CalzadoFormPage> createState() => _CalzadoFormPageState();
}

class _CalzadoFormPageState extends State<CalzadoFormPage> {
  bool _primerCargaCompletada = false;
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  String? _selectedTipoCalzadoId;

  bool _taco = false;
  bool _plataforma = false;
  bool _tacoCheckbox = false;
  bool _plataformaCheckbox = false;
  String? _iconoSeleccionado; // 🔹 Nuevo: icono seleccionado

  bool get isEditing => widget.doc != null;
  bool _intentoGuardar = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();

    if (isEditing) {
      final data = widget.doc!.data() as Map<String, dynamic>;
      _nombreController.text = data['nombre'] ?? '';
      _precioController.text = (data['precio_real'] ?? 0.0).toStringAsFixed(2);
      _selectedTipoCalzadoId = data['tipo_calzado_id'];
      _tacoCheckbox = data['taco'] ?? false;
      _plataformaCheckbox = data['plataforma'] ?? false;
      _iconoSeleccionado = data['icono']; // 🔹 Cargar icono si existe
    }

    _nombreController.addListener(_validarFormulario);
    _precioController.addListener(_validarFormulario);

    WidgetsBinding.instance.addPostFrameCallback((_) => _validarFormulario());
  }

  void _validarFormulario() {
    final nombre = _nombreController.text.trim();
    final precio = _precioController.text.trim();

    final valido = nombre.isNotEmpty &&
        precio.isNotEmpty &&
        _selectedTipoCalzadoId != null &&
        _formKey.currentState?.validate() != false;

    setState(() {
      _isFormValid = valido;
    });
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
    setState(() => _intentoGuardar = true);

    if (!_formKey.currentState!.validate() || !_isFormValid) return;

    final tipoSnap = await FirebaseFirestore.instance
        .collection('tipo_calzado')
        .doc(_selectedTipoCalzadoId)
        .get();

    if (!tipoSnap.exists || !(tipoSnap.data()?['activo'] ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El tipo de calzado seleccionado ya no está disponible.'),
        ),
      );
      return;
    }

    final tipoData = tipoSnap.data() ?? {};
    final icono = tipoData['icono'] ?? _iconoSeleccionado ?? '';

    final precioText = _precioController.text.replaceAll("S/", "").trim();
    final precio = double.tryParse(precioText) ?? 0.0;

    final data = {
      'nombre': _nombreController.text.trim(),
      'precio_real': double.parse(precio.toStringAsFixed(2)),
      'usuario_creacion': widget.firstName,
      'fecha_creacion': FieldValue.serverTimestamp(),
      'tipo_calzado_id': _selectedTipoCalzadoId,
      'icono': icono, // 🔹 Guardamos el icono
      'activo': true,
      'taco': _tacoCheckbox,
      'plataforma': _plataformaCheckbox,
    };

    try {
      if (isEditing) {
        await FirebaseFirestore.instance
            .collection('calzado')
            .doc(widget.doc!.id)
            .update(data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Calzado actualizado correctamente ✏️')),
        );
      } else {
        await FirebaseFirestore.instance.collection('calzado').add(data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Calzado agregado correctamente ✅')),
        );
      }

      if (mounted) Navigator.pop(context, true); // 🔹 Enviar true para recargar
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Designwidgets().appBarMain(
        isEditing ? "Editar Calzado" : "Agregar Calzado",
        isOnline: widget.isOnline,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20)
            .copyWith(top: 24, bottom: 40),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            onChanged: _validarFormulario,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // 🔸 Tipo de calzado
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('tipo_calzado')
                      .where('activo', isEqualTo: true)
                      .orderBy('fecha_creacion', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!_primerCargaCompletada &&
                        snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasData) _primerCargaCompletada = true;

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      final mostrarAdvertencia = _intentoGuardar;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No hay tipos de calzado disponibles.',
                              style: TextStyle(
                                color: mostrarAdvertencia
                                    ? Colors.red
                                    : Colors.black87,
                                fontSize: 16,
                                fontWeight: mostrarAdvertencia
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Text(
                                '(Debe agregar uno primero)',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                      );
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
                            children: [
                              if (icono.toString().endsWith('.png') ||
                                  icono.toString().endsWith('.jpg'))
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Image.asset(
                                    icono,
                                    width: 28,
                                    height: 28,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.image, size: 24),
                                  ),
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(icono.toString(),
                                      style: const TextStyle(fontSize: 22)),
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
                      onChanged: (val) async {
                        setState(() => _selectedTipoCalzadoId = val);
                        if (val != null) {
                          final tipoSnap = await FirebaseFirestore.instance
                              .collection('tipo_calzado')
                              .doc(val)
                              .get();
                          if (tipoSnap.exists) {
                            setState(() {
                              _iconoSeleccionado =
                                  tipoSnap.data()?['icono'] ?? '';
                              _taco =
                                  tipoSnap.data()?['taco'] as bool? ?? false;
                              _plataforma = tipoSnap.data()?['plataforma']
                                      as bool? ??
                                  false;
                            });
                          }
                        }
                        _validarFormulario();
                      },
                      validator: (v) =>
                          v == null ? 'Seleccione un tipo de calzado' : null,
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Nombre
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Ingrese un nombre' : null,
                ),
                const SizedBox(height: 16),

                // Precio
                TextFormField(
                  controller: _precioController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}$')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Precio real',
                    prefixText: 'S/ ',
                    border: OutlineInputBorder(),
                  ),
                  validator: validarPrecio,
                ),
                const SizedBox(height: 16),

                // Taco / Plataforma
                if (_selectedTipoCalzadoId != null)
                  Column(
                    children: [
                      if (_taco)
                        Row(
                          children: [
                            const Text('¿Tiene Taco?',
                                style: TextStyle(fontSize: 16)),
                            Checkbox(
                              value: _tacoCheckbox,
                              onChanged: (val) =>
                                  setState(() => _tacoCheckbox = val ?? false),
                            ),
                          ],
                        ),
                      if (_plataforma)
                        Row(
                          children: [
                            const Text('¿Tiene Plataforma?',
                                style: TextStyle(fontSize: 16)),
                            Checkbox(
                              value: _plataformaCheckbox,
                              onChanged: (val) => setState(
                                  () => _plataformaCheckbox = val ?? false),
                            ),
                          ],
                        ),
                    ],
                  ),

                const SizedBox(height: 16),

                // Botón Guardar / Actualizar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isFormValid ? _guardarCalzado : null,
                    icon: Icon(isEditing ? Icons.save_as : Icons.save),
                    label: Text(
                        isEditing ? 'Actualizar Calzado' : 'Guardar Calzado'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isFormValid ? Colors.white : Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
