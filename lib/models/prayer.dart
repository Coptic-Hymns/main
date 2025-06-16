import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/storage.dart';

class Prayer {
  int? id;
  String? firestoreId;
  String? title;
  String? content;
  String? category;
  String? language;
  String? notes;
  bool? isFavorite;
  DateTime? createdAt;
  DateTime? updatedAt;

  Prayer({
    this.id,
    this.firestoreId,
    this.title,
    this.content,
    this.category,
    this.language,
    this.notes,
    this.isFavorite = false,
    this.createdAt,
    this.updatedAt,
  });

  static Prayer fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Prayer(
      firestoreId: doc.id,
      title: data['title'],
      content: data['content'],
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
      'content': content,
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
      'content': content,
      'category': category,
      'language': language,
      'notes': notes,
      'isFavorite': isFavorite,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static Prayer fromJson(Map<String, dynamic> json) {
    return Prayer(
      id: json['id'],
      firestoreId: json['firestoreId'],
      title: json['title'],
      content: json['content'],
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
