import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class UploadService {
  // TODO: Replace with the actual endpoint provided by the user
  static const String _uploadEndpoint =
      'https://unimarket-mw.com/autoprint/upload_document.php';

  /// Uploads a file to the external endpoint and returns the download URL.
  static Future<String> uploadFile({
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_uploadEndpoint));

      // Add the file as a multipart file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Assuming the response contains a 'url' or 'link' field
        final String? fileUrl = data['url'] ?? data['link'] ?? data['fileUrl'];
        if (fileUrl != null) {
          return fileUrl;
        } else {
          throw Exception('Upload successful but no URL returned in response');
        }
      } else {
        throw Exception(
            'Failed to upload file. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading file: $e');
    }
  }
}
