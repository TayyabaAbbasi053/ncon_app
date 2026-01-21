import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ImgBBUploadService {
  static const String apiKey = '4bc05eed8fe4d82ba08d1b0572e1e848'; // your key

  static Future<String?> uploadImage(File imageFile) async {
    try {
      final url = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');
      
      // Read image file as bytes
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Create multipart request
      final request = http.MultipartRequest('POST', url)
        ..fields['image'] = base64Image;

      print('🔄 Sending request to ImgBB...');
      
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final data = jsonDecode(responseData);

      if (response.statusCode == 200) {
        final imageUrl = data['data']['url'];
        print('✅ Image uploaded successfully: $imageUrl');
        return imageUrl;
      } else {
        print('❌ Upload failed with status: ${response.statusCode}');
        print('❌ Response: $responseData');
        return null;
      }
    } catch (e) {
      print('❌ Exception during upload: $e');
      return null;
    }
  }
}