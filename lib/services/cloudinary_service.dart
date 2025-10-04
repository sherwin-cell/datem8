import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  final Cloudinary _cloudinary;

  CloudinaryService()
      : _cloudinary = Cloudinary.full(
          apiKey: dotenv.env['CLOUDINARY_API_KEY'] ?? '',
          apiSecret: dotenv.env['CLOUDINARY_API_SECRET'] ?? '',
          cloudName: dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '',
        );

  final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  Future<File?> pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) return File(pickedFile.path);
    } catch (e) {
      debugPrint("Image picking error: $e");
    }
    return null;
  }

  /// Take a photo using camera
  Future<File?> takePhoto() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) return File(pickedFile.path);
    } catch (e) {
      debugPrint("Camera capture error: $e");
    }
    return null;
  }

  /// Upload image to Cloudinary and return the URL
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
        return response.secureUrl; // Full URL
      } else {
        debugPrint('Cloudinary upload failed: ${response.error}');
      }
    } catch (e) {
      debugPrint("Cloudinary upload exception: $e");
    }
    return null;
  }

  /// Pick an image from gallery and upload directly
  Future<String?> pickAndUploadImage({String folder = 'datem8'}) async {
    final file = await pickImage();
    if (file != null) return await uploadImage(file, folder: folder);
    return null;
  }

  /// Take a photo with camera and upload directly
  Future<String?> takePhotoAndUpload({String folder = 'datem8'}) async {
    final file = await takePhoto();
    if (file != null) return await uploadImage(file, folder: folder);
    return null;
  }
}
