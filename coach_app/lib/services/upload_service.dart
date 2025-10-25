import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/supabase_config.dart';

/// Supabase Upload Service for Photos and Documents
class UploadService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final ImagePicker _picker = ImagePicker();

  // ==================== PHOTO UPLOAD ====================
  
  /// Select and upload profile photo
  static Future<String?> selectAndUploadPhoto(BuildContext context) async {
    try {
      // Request permissions
      final cameraStatus = await Permission.camera.request();
      final photosStatus = await Permission.photos.request();
      
      if (cameraStatus.isDenied && photosStatus.isDenied) {
        _showError(context, 'Camera and photo permissions are required');
        return null;
      }

      // Show source selection
      final source = await _showPhotoSourceDialog(context);
      if (source == null) return null;

      // Pick image
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return null;

      // Show upload progress
      _showUploadProgress(context, 'Uploading photo...');

      // Read image bytes
      final bytes = await image.readAsBytes();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'avatars/$fileName';

      // Check if demo mode
      if (!_isSupabaseConfigured()) {
        Navigator.pop(context); // Close progress dialog
        _showSuccess(context, 'Photo uploaded (Demo Mode)');
        // Return a placeholder URL for demo
        return 'https://via.placeholder.com/150';
      }

      // Upload to Supabase Storage
      final uploadPath = await _supabase.storage
          .from('avatars')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      Navigator.pop(context); // Close progress dialog

      // Get public URL
      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(filePath);

      _showSuccess(context, 'Photo uploaded successfully!');
      return publicUrl;
      
    } catch (e) {
      Navigator.pop(context); // Close any dialogs
      _showError(context, 'Failed to upload photo: $e');
      return null;
    }
  }

  // ==================== DOCUMENT UPLOAD ====================
  
  /// Upload medical clearance or other documents
  static Future<String?> uploadDocument(
    BuildContext context, {
    String documentType = 'medical_clearance',
  }) async {
    try {
      // Pick document
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        withData: true,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;

      // Validate file size (max 10MB)
      if (file.size > 10 * 1024 * 1024) {
        _showError(context, 'File size must be less than 10MB');
        return null;
      }

      // Show upload progress
      _showUploadProgress(context, 'Uploading ${file.name}...');

      final bytes = file.bytes!;
      final fileName = '${documentType}_${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final filePath = 'documents/$fileName';

      // Check if demo mode
      if (!_isSupabaseConfigured()) {
        Navigator.pop(context); // Close progress dialog
        _showSuccess(context, 'Document uploaded (Demo Mode)');
        return 'demo-document-url';
      }

      // Upload to Supabase Storage
      await _supabase.storage
          .from('documents')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: _getContentType(file.extension ?? 'pdf'),
              cacheControl: '3600',
              upsert: false,
            ),
          );

      Navigator.pop(context); // Close progress dialog

      // Get signed URL (valid for 1 year)
      final signedUrl = await _supabase.storage
          .from('documents')
          .createSignedUrl(filePath, 60 * 60 * 24 * 365);

      // Store metadata in database (optional)
      try {
        await _supabase.from('documents_metadata').insert({
          'file_path': filePath,
          'file_name': file.name,
          'file_size': file.size,
          'document_type': documentType,
          'uploaded_at': DateTime.now().toIso8601String(),
          'uploaded_by': _supabase.auth.currentUser?.id,
        });
      } catch (e) {
        debugPrint('Failed to store document metadata: $e');
        // Continue anyway, upload was successful
      }

      _showSuccess(context, 'Document uploaded successfully!');
      return signedUrl;
      
    } catch (e) {
      Navigator.pop(context); // Close any dialogs
      _showError(context, 'Failed to upload document: $e');
      return null;
    }
  }

  // ==================== HELPER METHODS ====================

  /// Show photo source selection dialog
  static Future<ImageSource?> _showPhotoSourceDialog(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Photo Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.camera_alt, color: Colors.blue),
              ),
              title: const Text('Take Photo'),
              subtitle: const Text('Use camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.photo_library, color: Colors.green),
              ),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select existing photo'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  /// Show upload progress dialog
  static void _showUploadProgress(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Show success message
  static void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Show error message
  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Check if Supabase is properly configured
  static bool _isSupabaseConfigured() {
    return SupabaseConfig.isRealConfig && !SupabaseConfig.isDemoMode;
  }

  /// Get content type for file
  static String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  // ==================== STORAGE BUCKET SETUP ====================
  
  /// Setup storage buckets (call this during app initialization)
  static Future<void> setupStorageBuckets() async {
    if (!_isSupabaseConfigured()) {
      debugPrint('Supabase not configured, skipping bucket setup');
      return;
    }

    try {
      // Check if buckets exist, create if not
      // Note: This requires service_role key for admin operations
      // In production, create buckets manually in Supabase dashboard
      
      debugPrint('Storage buckets should be created in Supabase dashboard:');
      debugPrint('1. Go to Storage in Supabase dashboard');
      debugPrint('2. Create bucket: "avatars" (public)');
      debugPrint('3. Create bucket: "documents" (private)');
      debugPrint('4. Set up RLS policies for authenticated uploads');
    } catch (e) {
      debugPrint('Storage bucket setup note: $e');
    }
  }
}

