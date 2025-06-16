import 'package:cloud_firestore/cloud_firestore.dart';

class Feast {
  int? id;
  String? firestoreId;
  String? title;
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

  static Feast fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Feast(
      firestoreId: doc.id,
      title: data['title'],
      date: (data['date'] as Timestamp?)?.toDate(),
      name: data['name'],
      description: data['description'],
      imageUrl: data['imageUrl'],
      category: data['category'],
      language: data['language'],
      notes: data['notes'],
      isFavorite: data['isFavorite'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firestoreId': firestoreId,
      'title': title,
      'date': date?.toIso8601String(),
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      'language': language,
      'notes': notes,
      'isFavorite': isFavorite,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static Feast fromJson(Map<String, dynamic> json) {
    return Feast(
      id: json['id'],
      firestoreId: json['firestoreId'],
      title: json['title'],
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      name: json['name'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      category: json['category'],
      language: json['language'],
      notes: json['notes'],
      isFavorite: json['isFavorite'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
}
