import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../models/tarea.dart';

class CreateTaskScreen extends StatefulWidget {
  final Tarea? tarea;

  const CreateTaskScreen({super.key, this.tarea});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  DateTime? _selectedDate;
  bool _isCompletada = false;

  final _firestoreService = FirestoreService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    if (widget.tarea != null) {
      _tituloController.text = widget.tarea!.titulo;
      _descripcionController.text = widget.tarea!.descripcion ?? '';
      _selectedDate = widget.tarea!.fechaEntrega;
      _isCompletada = widget.tarea!.completada;
    }
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (widget.tarea == null) {
          await _firestoreService.createTarea(
            titulo: _tituloController.text.trim(),
            descripcion: _descripcionController.text.trim().isNotEmpty
                ? _descripcionController.text.trim()
                : null,
            fechaEntrega: _selectedDate,
            userId: _currentUserId,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tarea creada exitosamente')),
          );
        } else {
          await _firestoreService.updateTarea(
            tareaId: widget.tarea!.id,
            titulo: _tituloController.text.trim(),
            descripcion: _descripcionController.text.trim().isNotEmpty
                ? _descripcionController.text.trim()
                : null,
            fechaEntrega: _selectedDate,
            completada: _isCompletada,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tarea actualizada exitosamente')),
          );
        }
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar la tarea: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tarea == null ? 'Nueva Tarea' : 'Editar Tarea'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTask,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, introduce un título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción (Opcional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDate == null
                          ? 'Fecha de Entrega: No seleccionada'
                          : 'Fecha de Entrega: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                    ),
                  ),
                  TextButton(
                    onPressed: _pickDate,
                    child: const Text('Seleccionar Fecha'),
                  ),
                ],
              ),
              if (widget.tarea != null)
                SwitchListTile(
                  title: const Text('Completada'),
                  value: _isCompletada,
                  onChanged: (bool value) {
                    setState(() {
                      _isCompletada = value;
                    });
                  },
                ),
              const SizedBox(height: 24.0),
              Center(
                child: ElevatedButton(
                  onPressed: _saveTask,
                  child: Text(widget.tarea == null ? 'Crear Tarea' : 'Guardar Cambios'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}