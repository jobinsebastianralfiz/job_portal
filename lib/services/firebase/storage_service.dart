import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload File
  Future<String?> uploadFile(File file, String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // Upload Profile Image
  Future<String?> uploadProfileImage(File image, String userId) async {
    final extension = path.extension(image.path);
    final storagePath = 'users/$userId/profile/profile_${DateTime.now().millisecondsSinceEpoch}$extension';
    return uploadFile(image, storagePath);
  }

  // Upload Resume
  Future<String?> uploadResume(File resume, String userId) async {
    final extension = path.extension(resume.path);
    final storagePath = 'resumes/$userId/resume_${DateTime.now().millisecondsSinceEpoch}$extension';
    return uploadFile(resume, storagePath);
  }

  // Upload Company Logo
  Future<String?> uploadCompanyLogo(File logo, String companyId) async {
    final extension = path.extension(logo.path);
    final storagePath = 'companies/$companyId/logo/logo_${DateTime.now().millisecondsSinceEpoch}$extension';
    return uploadFile(logo, storagePath);
  }

  // Upload Job Image
  Future<String?> uploadJobImage(File image, String jobId) async {
    final extension = path.extension(image.path);
    final storagePath = 'jobs/$jobId/image_${DateTime.now().millisecondsSinceEpoch}$extension';
    return uploadFile(image, storagePath);
  }

  // Upload Company Gallery Image
  Future<String?> uploadCompanyGalleryImage(String companyId, File image) async {
    final extension = path.extension(image.path);
    final storagePath = 'companies/$companyId/gallery/image_${DateTime.now().millisecondsSinceEpoch}$extension';
    return uploadFile(image, storagePath);
  }

  // Upload Document
  Future<String?> uploadDocument(File document, String userId, String folder) async {
    final extension = path.extension(document.path);
    final fileName = path.basenameWithoutExtension(document.path);
    final storagePath = 'documents/$userId/$folder/${fileName}_${DateTime.now().millisecondsSinceEpoch}$extension';
    return uploadFile(document, storagePath);
  }

  // Upload Chat Attachment
  Future<String?> uploadChatAttachment(File file, String chatId) async {
    final extension = path.extension(file.path);
    final storagePath = 'chat_attachments/$chatId/attachment_${DateTime.now().millisecondsSinceEpoch}$extension';
    return uploadFile(file, storagePath);
  }

  // Delete File
  Future<bool> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get Download URL
  Future<String?> getDownloadUrl(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }
}
