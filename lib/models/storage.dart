import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';

abstract class Storage {
  Future<void> init();
  Future<void> save<T>(String key, T value);
  Future<T?> get<T>(String key);
  Future<void> delete(String key);
  Future<void> clear();
}

class WebStorage implements Storage {
  late SharedPreferences _prefs;

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Future<void> save<T>(String key, T value) async {
    if (value == null) {
      await _prefs.remove(key);
      return;
    }
    if (value is String) {
      await _prefs.setString(key, value);
    } else if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    } else {
      await _prefs.setString(key, jsonEncode(value));
    }
  }

  @override
  Future<T?> get<T>(String key) async {
    final value = _prefs.get(key);
    if (value == null) return null;
    if (T == String) return value as T;
    if (T == bool) return value as T;
    if (T == int) return value as T;
    if (T == double) return value as T;
    if (value is String) {
      try {
        return jsonDecode(value) as T;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> delete(String key) async {
    await _prefs.remove(key);
  }

  @override
  Future<void> clear() async {
    await _prefs.clear();
  }
}

class NativeStorage implements Storage {
  late Isar _isar;

  @override
  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [],
      directory: dir.path,
    );
  }

  @override
  Future<void> save<T>(String key, T value) async {
    // Implement Isar storage
  }

  @override
  Future<T?> get<T>(String key) async {
    // Implement Isar retrieval
    return null;
  }

  @override
  Future<void> delete(String key) async {
    // Implement Isar deletion
  }

  @override
  Future<void> clear() async {
    // Implement Isar clear
  }
}

Storage getStorage() {
  if (kIsWeb) {
    return WebStorage();
  }
  return NativeStorage();
}
