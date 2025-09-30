import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  CloudinaryService._();

  static CloudinaryPublic? _instance;

  static CloudinaryPublic get _client {
    _instance ??= CloudinaryPublic(
      const String.fromEnvironment(
        'CLOUDINARY_CLOUD_NAME',
        defaultValue: 'dlfto8vov',
      ),
      const String.fromEnvironment(
        'CLOUDINARY_UPLOAD_PRESET',
        defaultValue: 'campusconnect_images',
      ),
      cache: false,
    );
    return _instance!;
  }

  static Future<String> uploadImageFile(
    File file, {
    String folder = 'avatars',
  }) async {
    final response = await _client.uploadFile(
      CloudinaryFile.fromFile(
        file.path,
        folder: folder,
        resourceType: CloudinaryResourceType.Image,
      ),
    );
    return response.secureUrl;
  }
}
