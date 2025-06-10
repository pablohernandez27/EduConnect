import 'package:cloud_firestore/cloud_firestore.dart';

class Foro {
  final String id;
  final String title;
  final String description;
  bool isFavorite;
  final String createdBy;
  final DateTime createdAt;

  Foro({
    required this.id,
    required this.title,
    required this.description,
    this.isFavorite = false,
    required this.createdBy,
    required this.createdAt,
  });

  factory Foro.fromMap(String id, Map<String, dynamic> data) {
    return Foro(
      id: id,
      title: data['title'],
      description: data['description'],
      isFavorite: data['isFavorite'] ?? false,
      createdBy: data['createdBy'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
