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

  Map<String, String> get title => Map<String, String>.from(jsonDecode(titleJson));
  List<Map<String, String>> get blocks => List<Map<String, String>>.from(jsonDecode(blocksJson));
  List<String> get tags => List<String>.from(jsonDecode(tagsJson));

  set title(Map<String, String> value) => titleJson = jsonEncode(value);
  set blocks(List<Map<String, String>> value) => blocksJson = jsonEncode(value);
  set tags(List<String> value) => tagsJson = jsonEncode(value);

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