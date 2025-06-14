import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:isar/isar.dart';

part 'prayer.g.dart';

@collection
class Prayer {
  @Index(type: IndexType.value)
  String? id;

  @Index(type: IndexType.value)
  String? firestoreId;

  @Index(type: IndexType.value)
  String? title;

  @Index(type: IndexType.value)
  String? category;

  String? content;
  String? language;
  String? notes;
  String? documentUrl;
  bool? isFavorite;
  DateTime? createdAt;
  DateTime? updatedAt;

  Prayer({
    this.id,
    this.firestoreId,
    this.title,
    this.category,
    this.content,
    this.language,
    this.notes,
    this.documentUrl,
    this.isFavorite = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Prayer.fromFirestore(firestore.DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Prayer(
      id: doc.id,
      firestoreId: doc.id,
      title: data['title'],
      category: data['category'],
      content: data['content'],
      language: data['language'],
      notes: data['notes'],
      documentUrl: data['documentUrl'],
      isFavorite: data['isFavorite'] ?? false,
      createdAt: (data['createdAt'] as firestore.Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as firestore.Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'category': category,
      'content': content,
      'language': language,
      'notes': notes,
      'documentUrl': documentUrl,
      'isFavorite': isFavorite,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Prayer.fromJson(Map<String, dynamic> json) {
    return Prayer(
      id: json['id'] as String?,
      firestoreId: json['id'] as String?,
      title: json['title'] as String?,
      category: json['category'] as String?,
      content: json['content'] as String?,
      notes: json['notes'] as String?,
      documentUrl: json['documentUrl'] as String?,
      isFavorite: json['isFavorite'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'content': content,
      'notes': notes,
      'documentUrl': documentUrl,
      'isFavorite': isFavorite,
    };
  }
}
