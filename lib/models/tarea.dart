import 'package:cloud_firestore/cloud_firestore.dart';

class Tarea {
  final String id;
  final String titulo;
  final String? descripcion;
  final DateTime? fechaEntrega;
  final bool completada;
  final String userId;
  final DateTime createdAt;
  final bool tieneFechaEntrega;

  Tarea({
    required this.id,
    required this.titulo,
    this.descripcion,
    this.fechaEntrega,
    required this.completada,
    required this.userId,
    required this.createdAt,
    required this.tieneFechaEntrega,
  });

  factory Tarea.fromMap(String id, Map<String, dynamic> data) {
    return Tarea(
      id: id,
      titulo: data['titulo'] as String,
      descripcion: data['descripcion'] as String?,
      fechaEntrega: data['fechaEntrega'] != null
          ? (data['fechaEntrega'] as Timestamp).toDate()
          : null,
      completada: data['completada'] as bool,
      userId: data['userId'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      tieneFechaEntrega: data['tieneFechaEntrega'] as bool? ?? (data['fechaEntrega'] != null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'fechaEntrega': fechaEntrega != null
          ? Timestamp.fromDate(fechaEntrega!)
          : null,
      'completada': completada,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'tieneFechaEntrega': tieneFechaEntrega,
    };
  }
}