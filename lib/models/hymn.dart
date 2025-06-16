import 'package:cloud_firestore/cloud_firestore.dart' hide Index;
import 'package:flutter/foundation.dart';
import '../models/storage.dart';

class Hymn {
  int? id;
  String? firestoreId;
  String? title;
  String? category;
  String? lyrics;
  String? audioUrl;
  String? notes;
  String? language;
  bool? isFavorite;
  DateTime? createdAt;
  DateTime? updatedAt;

  Hymn({
    this.id,
    this.firestoreId,
    this.title,
    this.category,
    this.lyrics,
    this.audioUrl,
    this.notes,
    this.language,
    this.isFavorite = false,
    this.createdAt,
    this.updatedAt,
  });

  static Hymn fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Hymn(
      firestoreId: doc.id,
      title: data['title'],
      category: data['category'],
      lyrics: data['lyrics'],
      audioUrl: data['audioUrl'],
      notes: data['notes'],
      language: data['language'],
      isFavorite: data['isFavorite'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'category': category,
      'lyrics': lyrics,
      'audioUrl': audioUrl,
      'notes': notes,
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
      'title': title,
      'category': category,
      'lyrics': lyrics,
      'audioUrl': audioUrl,
      'notes': notes,
      'language': language,
      'isFavorite': isFavorite,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static Hymn fromJson(Map<String, dynamic> json) {
    return Hymn(
      id: json['id'],
      firestoreId: json['firestoreId'],
      title: json['title'],
      category: json['category'],
      lyrics: json['lyrics'],
      audioUrl: json['audioUrl'],
      notes: json['notes'],
      language: json['language'],
      isFavorite: json['isFavorite'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
}
