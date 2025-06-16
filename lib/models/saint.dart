import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/storage.dart';

class Saint {
  int? id;
  String? firestoreId;
  String? name;
  String? feastDay;
  String? biography;
  String? imageUrl;
  String? category;
  String? language;
  bool? isFavorite;
  DateTime? createdAt;
  DateTime? updatedAt;

  Saint({
    this.id,
    this.firestoreId,
    this.name,
    this.feastDay,
    this.biography,
    this.imageUrl,
    this.category,
    this.language,
    this.isFavorite = false,
    this.createdAt,
    this.updatedAt,
  });

  static Saint fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Saint(
      firestoreId: doc.id,
      name: data['name'],
      feastDay: data['feastDay'],
      biography: data['biography'],
      imageUrl: data['imageUrl'],
      category: data['category'],
      language: data['language'],
      isFavorite: data['isFavorite'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'feastDay': feastDay,
      'biography': biography,
      'imageUrl': imageUrl,
      'category': category,
      'language': language,
      'isFavorite': isFavorite,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firestoreId': firestoreId,
      'name': name,
      'feastDay': feastDay,
      'biography': biography,
      'imageUrl': imageUrl,
      'category': category,
      'language': language,
      'isFavorite': isFavorite,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static Saint fromJson(Map<String, dynamic> json) {
    return Saint(
      id: json['id'],
      firestoreId: json['firestoreId'],
      name: json['name'],
      feastDay: json['feastDay'],
      biography: json['biography'],
      imageUrl: json['imageUrl'],
      category: json['category'],
      language: json['language'],
      isFavorite: json['isFavorite'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
}
