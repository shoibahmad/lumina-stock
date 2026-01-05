import 'dart:convert';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart';

class CloudinaryService {
  static const String cloudName = 'dg4af7ia9';
  static const String apiKey = '865816251161466';
  static const String apiSecret = '8w64_aQW6BAZ6dij5KXSXewmk8U';

  Future<String?> uploadImage(XFile imageFile) async {
    try {
      debugPrint('CloudinaryService: Starting SIGNED upload for ${imageFile.name}');
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      
      final int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // Signature generation: https://cloudinary.com/documentation/upload_images#generating_authentication_signatures
      // Parameters must be sorted alphabetically. We are only using 'timestamp'.
      // String to sign: "timestamp=1234567890" + api_secret
      final String paramsToSign = 'timestamp=$timestamp$apiSecret';
      final String signature = sha1.convert(utf8.encode(paramsToSign)).toString();
      
      final request = http.MultipartRequest('POST', url)
        ..fields['api_key'] = apiKey
        ..fields['timestamp'] = timestamp.toString()
        ..fields['signature'] = signature;
      
      debugPrint('CloudinaryService: Reading bytes...');
      final bytes = await imageFile.readAsBytes();
      debugPrint('CloudinaryService: Bytes read (${bytes.length}). Adding to request...');
      
      request.files.add(http.MultipartFile.fromBytes(
        'file', 
        bytes, 
        filename: imageFile.name
      ));

      debugPrint('CloudinaryService: Sending request...');
      final response = await request.send().timeout(const Duration(seconds: 45));
      debugPrint('CloudinaryService: Response received. Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);
        debugPrint('CloudinaryService: Upload successful. URL: ${jsonMap['secure_url']}');
        return jsonMap['secure_url'];
      } else {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        debugPrint('Cloudinary Upload Error: ${response.statusCode} - $responseString');
        throw Exception('Cloudinary Error: ${response.statusCode} - $responseString');
      }
    } catch (e) {
      debugPrint('Error uploading to Cloudinary: $e');
      rethrow; 
    }
  }

  Future<XFile?> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    return pickedFile; 
  }
}
