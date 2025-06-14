import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:isar/isar.dart';

part 'hymn.g.dart';

@collection
class Hymn {
  @Id()
  String id = '';

  @Index(type: IndexType.value)
  String? title;

  @Index(type: IndexType.value)
  String? category;

  String? lyrics;
  String? audioUrl;
  String? notes;
  String? language;
  bool? isFavorite;
  DateTime? createdAt;
  DateTime? updatedAt;

  Hymn({
    required this.id,
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

  factory Hymn.fromFirestore(firestore.DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Hymn(
      id: doc.id,
      title: data['title'],
      category: data['category'],
      lyrics: data['lyrics'],
      audioUrl: data['audioUrl'],
      notes: data['notes'],
      language: data['language'],
      isFavorite: data['isFavorite'] ?? false,
      createdAt: (data['createdAt'] as firestore.Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as firestore.Timestamp?)?.toDate(),
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
}
