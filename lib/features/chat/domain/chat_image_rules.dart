import 'package:image_picker/image_picker.dart';

/// Server limit for `POST /chat/upload-image`.
const chatImageMaxBytes = 5 * 1024 * 1024;

const _allowedMimeTypes = {
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
};

/// MIME type sent with the upload; falls back to the file extension and
/// finally to JPEG (what the picker produces when it re-encodes).
String chatImageMimeType(XFile file) {
  final declared = file.mimeType?.toLowerCase().trim();
  if (declared != null && _allowedMimeTypes.contains(declared)) return declared;
  final name = file.name.toLowerCase();
  if (name.endsWith('.png')) return 'image/png';
  if (name.endsWith('.webp')) return 'image/webp';
  if (name.endsWith('.gif')) return 'image/gif';
  return 'image/jpeg';
}

/// Returns a user-facing reason the photo cannot be sent, or `null`.
String? chatImageRejection({required String fileName, required int bytes}) {
  final name = fileName.toLowerCase();
  const unsupported = ['.heic', '.heif', '.bmp', '.tif', '.tiff', '.svg'];
  if (unsupported.any(name.endsWith)) {
    return 'Only JPEG, PNG, WebP and GIF photos can be sent.';
  }
  if (bytes <= 0) return 'This photo could not be read.';
  if (bytes > chatImageMaxBytes) return 'Photos must be 5 MB or smaller.';
  return null;
}
