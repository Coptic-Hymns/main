import 'package:isar/isar.dart';
import 'dart:convert';

part 'hymn_cache.g.dart';

@collection
class IsarHymn {
  Id id = Isar.autoIncrement;
  late String firestoreId;
  late String titleJson;
  late String blocksJson;
  late String tagsJson;
  late String season;
  String? audioUrl;
  String? youtubeUrl;
  DateTime? createdAt;
  DateTime? updatedAt;

  // Accessors to parse JSON strings when needed
  @ignore
  Map<String, String> get titleMap => Map<String, String>.from(jsonDecode(titleJson));
  @ignore
  List<Map<String, String>> get blocksList => List<Map<String, String>>.from(jsonDecode(blocksJson));
  @ignore
  List<String> get tagsList => List<String>.from(jsonDecode(tagsJson));

  static IsarHymn fromFirestore(String id, Map<String, dynamic> data) {
    return IsarHymn()
      ..firestoreId = id
      ..titleJson = jsonEncode(data['title'] ?? {})
      ..blocksJson = jsonEncode(data['blocks'] ?? [])
      ..tagsJson = jsonEncode(data['tags'] ?? [])
      ..season = data['season'] ?? ''
      ..audioUrl = data['audioUrl']
      ..youtubeUrl = data['youtubeUrl']
      ..createdAt = (data['createdAt'] as Timestamp?)?.toDate()
      ..updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': jsonDecode(titleJson),
      'blocks': jsonDecode(blocksJson),
      'tags': jsonDecode(tagsJson),
      'season': season,
      'audioUrl': audioUrl,
      'youtubeUrl': youtubeUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
} 