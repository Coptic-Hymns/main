import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:isar/isar.dart';

part 'feast.g.dart';

@collection
class Feast {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  String? firestoreId;

  @Index(type: IndexType.value)
  String? name;

  @Index(type: IndexType.value)
  DateTime? date;

  String? description;
  String? imageUrl;
  String? category;
  String? language;
  bool? isFavorite;
  DateTime? createdAt;
  DateTime? updatedAt;

  Feast({
    this.firestoreId,
    this.name,
    this.date,
    this.description,
    this.imageUrl,
    this.category,
    this.language,
    this.isFavorite = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Feast.fromFirestore(firestore.DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Feast(
      firestoreId: doc.id,
      name: data['name'],
      date: (data['date'] as firestore.Timestamp?)?.toDate(),
      description: data['description'],
      imageUrl: data['imageUrl'],
      category: data['category'],
      language: data['language'],
      isFavorite: data['isFavorite'] ?? false,
      createdAt: (data['createdAt'] as firestore.Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as firestore.Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'date': date,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      'language': language,
      'isFavorite': isFavorite,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Feast.fromJson(Map<String, dynamic> json) {
    return Feast(
      firestoreId: json['id'] as String?,
      name: json['name'] as String?,
      category: json['category'] as String?,
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : null,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      isFavorite: json['isFavorite'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': firestoreId,
      'name': name,
      'category': category,
      'date': date?.toIso8601String(),
      'description': description,
      'imageUrl': imageUrl,
      'isFavorite': isFavorite,
    };
  }
}
