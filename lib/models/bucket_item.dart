import 'package:cloud_firestore/cloud_firestore.dart';

class BucketItem {
  final String id;
  final String title;
  final bool completed;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? completedAt;

  BucketItem({
    required this.id,
    required this.title,
    required this.completed,
    required this.createdBy,
    required this.createdAt,
    this.completedAt,
  });

  factory BucketItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return BucketItem(
      id: doc.id,
      title: data['title'] ?? '',
      completed: data['completed'] ?? false,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'completed': completed,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
        'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      };
}