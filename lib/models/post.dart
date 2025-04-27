import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String text;
  final String createdBy;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.text,
    required this.createdBy,
    required this.createdAt,
  });

  factory Post.fromMap(String id, Map<String, dynamic> data) {
    return Post(
      id: id,
      text: data['text'],
      createdBy: data['createdBy'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
