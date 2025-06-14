import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

class FileUploadService {
  static Future<String?> pickAndUploadFile({
    required String collection,
    required String documentId,
    required String field,
    List<String>? allowedExtensions,
    String? fileType,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final fileName = path.basename(file.path);
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('$collection/$documentId/$field/$fileName');

        final uploadTask = storageRef.putFile(file);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        debugPrint('File uploaded successfully: $downloadUrl');
        return downloadUrl;
      }
    } catch (e) {
      debugPrint('Error uploading file: $e');
    }
    return null;
  }

  static Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(fileUrl);
      await ref.delete();
      debugPrint('File deleted successfully');
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }
} 