import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants.dart';

class ProgressPhoto {
  final String id;
  final String url;
  final DateTime date;
  final double? weightKg;
  final String? note;
  final String? aiAnalysis;

  ProgressPhoto({
    required this.id,
    required this.url,
    required this.date,
    this.weightKg,
    this.note,
    this.aiAnalysis,
  });

  factory ProgressPhoto.fromMap(Map<String, dynamic> map, String id) {
    return ProgressPhoto(
      id: id,
      url: map['url'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      weightKg: map['weightKg']?.toDouble(),
      note: map['note'],
      aiAnalysis: map['aiAnalysis'],
    );
  }

  Map<String, dynamic> toMap() => {
    'url': url,
    'date': Timestamp.fromDate(date),
    'weightKg': weightKg,
    'note': note,
    'aiAnalysis': aiAnalysis,
  };
}

class ProgressPhotosService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _claudeApiKey = 'API KEY';

  /// Upload photo to Firebase Storage
  Future<String?> uploadPhoto(String userId, File photo) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref('progress_photos/$userId/$timestamp.jpg');
      await ref.putFile(photo);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  /// Save progress photo record to Firestore
  Future<String?> savePhoto({
    required String userId,
    required String url,
    double? weightKg,
    String? note,
  }) async {
    try {
      final ref = await _db
          .collection('users')
          .doc(userId)
          .collection('progressPhotos')
          .add({
        'url': url,
        'date': Timestamp.now(),
        'weightKg': weightKg,
        'note': note,
      });
      return ref.id;
    } catch (e) {
      print('Save photo error: $e');
      return null;
    }
  }

  /// Get all progress photos for user
  Future<List<ProgressPhoto>> getPhotos(String userId) async {
    try {
      final snap = await _db
          .collection('users')
          .doc(userId)
          .collection('progressPhotos')
          .get();

      final list = snap.docs
          .map((d) => ProgressPhoto.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    } catch (e) {
      print('Get photos error: $e');
      return [];
    }
  }

  /// Delete a progress photo
  Future<bool> deletePhoto(String userId, String photoId, String photoUrl) async {
    try {
      // Delete from Firestore
      await _db
          .collection('users')
          .doc(userId)
          .collection('progressPhotos')
          .doc(photoId)
          .delete();

      // Delete from Storage
      try {
        await _storage.refFromURL(photoUrl).delete();
      } catch (_) {}

      return true;
    } catch (e) {
      print('Delete error: $e');
      return false;
    }
  }

  /// AI body analysis on a single photo (Gemini Vision)
  Future<String?> analyzeBody(String base64Image, {String? previousAnalysis}) async {
    try {
      final url = '${AppConstants.geminiApiUrl}/${AppConstants.geminiModel}:generateContent?key=${AppConstants.geminiApiKey}';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64Image,
                  }
                },
                {
                  'text': '''Analyze this fitness progress photo professionally and supportively. Provide insights on:

1. **Body Composition**: Overall physique, visible muscle definition
2. **Posture**: Alignment, symmetry observations
3. **Muscle Development**: Which areas show good development
4. **Suggestions**: Focus areas for balanced development

Keep the tone motivating and professional. Format as clear sections with emojis. Keep total under 200 words.
Do NOT make assumptions about weight, body fat percentage, or medical conditions.'''
                },
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 800,
          },
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['candidates'][0]['content']['parts'][0]['text'];
      } else {
        print('Gemini Body Analysis Error: ${response.statusCode} - ${response.body}');
      }
      return null;
    } catch (e) {
      print('AI Analysis error: $e');
      return null;
    }
  }

  /// Compare two photos with AI (Gemini Vision)
  Future<String?> comparePhotos(String base64Before, String base64After) async {
    try {
      final url = '${AppConstants.geminiApiUrl}/${AppConstants.geminiModel}:generateContent?key=${AppConstants.geminiApiKey}';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': 'This is the BEFORE photo:'},
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64Before,
                  }
                },
                {'text': 'This is the AFTER photo:'},
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64After,
                  }
                },
                {
                  'text': '''Compare these fitness progress photos. Provide a supportive, motivating analysis covering:

🎯 **Visible Changes**: What improvements are apparent
💪 **Muscle Development**: Areas showing growth or definition
📐 **Body Composition**: Overall physique changes
✨ **Highlights**: Biggest transformations visible
📋 **Next Focus**: Suggested areas to keep working on

Be honest but encouraging. If changes are subtle, acknowledge effort and consistency. Keep under 250 words. Format with clear sections and emojis.'''
                },
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1000,
          },
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['candidates'][0]['content']['parts'][0]['text'];
      } else {
        print('Gemini Compare Error: ${response.statusCode} - ${response.body}');
      }
      return null;
    } catch (e) {
      print('Comparison error: $e');
      return null;
    }
  }

  /// Update photo with AI analysis
  Future<void> updatePhotoAnalysis(String userId, String photoId, String analysis) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('progressPhotos')
        .doc(photoId)
        .update({'aiAnalysis': analysis});
  }
}
