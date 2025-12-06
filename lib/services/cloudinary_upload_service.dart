import 'dart:convert';
import 'dart:io' as io show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../data/datasources/remote_data_source.dart';

class CloudinaryUploadService {
  final RemoteDataSource _remoteDataSource;
  
  CloudinaryUploadService(this._remoteDataSource);
  
  /// Upload photo to Cloudinary using backend signature
  /// Returns secure_url of uploaded image
  Future<String> uploadCheckInPhoto(Uint8List imageBytes) async {
    try {
      // Step 1: Get upload signature from backend
      final signatureData = await _remoteDataSource.getUploadSignature();
      
      final signature = signatureData['signature'] as String;
      final timestamp = signatureData['timestamp'] as int;
      final cloudName = signatureData['cloudName'] as String;
      final apiKey = signatureData['apiKey'] as String;
      final uploadPreset = signatureData['uploadPreset'] as String;
      final folder = signatureData['folder'] as String;
      
      // Step 2: Upload directly to Cloudinary using HTTP POST
      final uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
      
      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      
      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'checkin.jpg',
        ),
      );
      
      // Add required parameters
      request.fields['signature'] = signature;
      request.fields['timestamp'] = timestamp.toString();
      request.fields['api_key'] = apiKey;
      request.fields['upload_preset'] = uploadPreset;
      if (folder.isNotEmpty) {
        request.fields['folder'] = folder;
      }
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final secureUrl = responseData['secure_url'] as String;
        
        // Step 3: Return secure_url
        return secureUrl;
      } else {
        throw Exception('Cloudinary upload failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to upload photo to Cloudinary: $e');
    }
  }
  
  /// Upload photo from file path (for mobile)
  Future<String> uploadCheckInPhotoFromPath(String filePath) async {
    if (kIsWeb) {
      throw UnsupportedError('File path upload not supported on web');
    }
    
    final file = io.File(filePath);
    final imageBytes = await file.readAsBytes();
    return uploadCheckInPhoto(imageBytes);
  }
}
