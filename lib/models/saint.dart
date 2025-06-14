import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:isar/isar.dart';

part 'saint.g.dart';

@collection
class Saint {
  @Index(type: IndexType.value)
  String? id;

  @Index(type: IndexType.value)
  String? firestoreId;

  @Index(type: IndexType.value)
  String? name;

  @Index(type: IndexType.value)
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

  factory Saint.fromFirestore(firestore.DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Saint(
      id: doc.id,
      firestoreId: doc.id,
      name: data['name'],
      feastDay: data['feastDay'],
      biography: data['biography'],
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
}
