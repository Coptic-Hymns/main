import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:isar/isar.dart';

part 'feast.g.dart';

@collection
class Feast {
  @Index(type: IndexType.value)
  String? id;

  @Index(type: IndexType.value)
  String? firestoreId;

  @Index(type: IndexType.value)
  String? title;

  @Index(type: IndexType.value)
  DateTime? date;

  String? name;
  String? description;
  String? imageUrl;
  String? category;
  String? language;
  String? notes;
  bool? isFavorite;
  DateTime? createdAt;
  DateTime? updatedAt;

  Feast({
    this.id,
    this.firestoreId,
    this.title,
    this.date,
    this.name,
    this.description,
    this.imageUrl,
    this.category,
    this.language,
    this.notes,
    this.isFavorite = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Feast.fromFirestore(firestore.DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Feast(
      id: doc.id,
      firestoreId: doc.id,
      title: data['title'],
      date: (data['date'] as firestore.Timestamp?)?.toDate(),
      name: data['name'],
      description: data['description'],
      imageUrl: data['imageUrl'],
      category: data['category'],
      language: data['language'],
      notes: data['notes'],
      isFavorite: data['isFavorite'] ?? false,
      createdAt: (data['createdAt'] as firestore.Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as firestore.Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'date': date,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      'language': language,
      'notes': notes,
      'isFavorite': isFavorite,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Feast.fromJson(Map<String, dynamic> json) {
    return Feast(
      id: json['id'] as String?,
      title: json['title'] as String?,
      category: json['category'] as String?,
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : null,
      name: json['name'] as String?,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      notes: json['notes'] as String?,
      isFavorite: json['isFavorite'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'date': date?.toIso8601String(),
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'notes': notes,
      'isFavorite': isFavorite,
    };
  }
}
