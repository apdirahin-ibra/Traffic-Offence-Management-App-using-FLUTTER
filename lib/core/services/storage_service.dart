import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload an evidence photo for a fine.
  /// Returns the download URL.
  Future<String> uploadEvidence({
    required String fineId,
    required String filePath,
    required String fileName,
  }) async {
    final ref = _storage.ref().child('evidence/$fineId/$fileName');
    final task = await ref.putFile(File(filePath));
    return await task.ref.getDownloadURL();
  }

  /// Upload appeal supporting document.
  Future<String> uploadAppealDoc({
    required String appealId,
    required String filePath,
    required String fileName,
  }) async {
    final ref = _storage.ref().child('appeals/$appealId/$fileName');
    final task = await ref.putFile(File(filePath));
    return await task.ref.getDownloadURL();
  }

  /// Upload a user profile image.
  Future<String> uploadProfileImage({
    required String userId,
    required String filePath,
  }) async {
    final ref = _storage.ref().child('profiles/$userId/avatar.jpg');
    final task = await ref.putFile(File(filePath));
    return await task.ref.getDownloadURL();
  }

  /// Delete a file by its full storage path.
  Future<void> deleteFile(String storagePath) async {
    await _storage.ref(storagePath).delete();
  }

  /// Get download URL for an existing path.
  Future<String> getDownloadUrl(String storagePath) async {
    return await _storage.ref(storagePath).getDownloadURL();
  }
}
