import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  final Cloudinary _cloudinary;
  final ImagePicker _picker = ImagePicker();

  CloudinaryService()
      : _cloudinary = Cloudinary.full(
          apiKey: dotenv.env['CLOUDINARY_API_KEY'] ?? '',
          apiSecret: dotenv.env['CLOUDINARY_API_SECRET'] ?? '',
          cloudName: dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '',
        );

  /// Pick a single image from gallery
  Future<File?> pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      return pickedFile != null ? File(pickedFile.path) : null;
    } catch (e) {
      debugPrint("❌ Image picking error: $e");
      return null;
    }
  }

  /// Pick multiple images from gallery
  Future<List<File>> pickMultipleImages() async {
    try {
      final files = await _picker.pickMultiImage();
      return files.map((x) => File(x.path)).toList();
    } catch (e) {
      debugPrint("❌ Multi-image picking error: $e");
      return [];
    }
  }

  /// Take a photo using the camera
  Future<File?> takePhoto() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      return pickedFile != null ? File(pickedFile.path) : null;
    } catch (e) {
      debugPrint("❌ Camera capture error: $e");
      return null;
    }
  }

  /// Upload a single image to Cloudinary
  Future<String?> uploadImage(File imageFile,
      {String folder = 'datem8'}) async {
    try {
      final response = await _cloudinary.uploadResource(
        CloudinaryUploadResource(
          filePath: imageFile.path,
          resourceType: CloudinaryResourceType.image,
          folder: folder,
        ),
      );

      if (response.isSuccessful) {
        debugPrint("✅ Uploaded: ${response.secureUrl}");
        return response.secureUrl;
      } else {
        debugPrint('❌ Cloudinary upload failed: ${response.error}');
      }
    } catch (e) {
      debugPrint("❌ Cloudinary upload exception: $e");
    }
    return null;
  }

  /// Pick and upload a single image
  Future<String?> pickAndUploadImage({String folder = 'datem8'}) async {
    final file = await pickImage();
    if (file == null) return null;
    return await uploadImage(file, folder: folder);
  }

  /// Take a photo and upload
  Future<String?> takePhotoAndUpload({String folder = 'datem8'}) async {
    final file = await takePhoto();
    if (file == null) return null;
    return await uploadImage(file, folder: folder);
  }

  /// Pick and upload multiple images
  Future<List<String>> pickAndUploadMultipleImages(
      {String folder = 'datem8'}) async {
    try {
      final files = await pickMultipleImages();
      if (files.isEmpty) return [];

      final List<Future<String?>> uploads =
          files.map((file) => uploadImage(file, folder: folder)).toList();

      final results = await Future.wait(uploads);
      final urls = results.whereType<String>().toList();
      debugPrint("✅ Uploaded ${urls.length} of ${files.length} images.");
      return urls;
    } catch (e) {
      debugPrint("❌ pickAndUploadMultipleImages error: $e");
      return [];
    }
  }
}
