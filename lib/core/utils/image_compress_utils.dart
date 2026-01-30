import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

@immutable
class ImageCompressOptions {
  const ImageCompressOptions({
    this.quality = 80,
    this.minWidth = 1280,
    this.minHeight = 1280,
    this.targetBytes,
    this.keepExif = true,
    this.format = CompressFormat.jpeg,
  }) : assert(quality >= 0 && quality <= 100),
       assert(minWidth > 0),
       assert(minHeight > 0);

  /// Initial quality (0..100).
  final int quality;

  /// Resize floor. The compressor will keep aspect ratio.
  final int minWidth;
  final int minHeight;

  /// Optional: try to compress further until the output is <= this size.
  /// Useful for camera images.
  final int? targetBytes;

  final bool keepExif;
  final CompressFormat format;
}

class ImageCompressUtils {
  /// Compress an image file, typically from camera.
  /// If compression fails, returns the original input file.
  static Future<File> compressImageFile(
    File input, {
    ImageCompressOptions options = const ImageCompressOptions(),
  }) async {
    if (!await _looksLikeImage(input.path)) return input;

    try {
      final dir = await getTemporaryDirectory();
      final baseName = 'img_${DateTime.now().millisecondsSinceEpoch}';
      final ext = _extFor(options.format);
      var outPath = p.join(dir.path, '$baseName$ext');

      final initial = await _compressOnce(
        inputPath: input.path,
        outPath: outPath,
        options: options,
        quality: options.quality,
      );

      if (initial == null) return input;

      final target = options.targetBytes;
      if (target == null || target <= 0) return initial;

      var out = initial;
      var q = options.quality;
      var size = await out.length();

      // Iteratively reduce quality if still too large.
      while (size > target && q > 25) {
        q = (q - 10).clamp(25, 100);
        outPath = p.join(dir.path, '${baseName}_q$q$ext');

        final next = await _compressOnce(
          inputPath: input.path,
          outPath: outPath,
          options: options,
          quality: q,
        );

        if (next == null) break;

        out = next;
        size = await out.length();
      }

      return out;
    } catch (_) {
      return input;
    }
  }

  static Future<File?> _compressOnce({
    required String inputPath,
    required String outPath,
    required ImageCompressOptions options,
    required int quality,
  }) async {
    final result = await FlutterImageCompress.compressAndGetFile(
      inputPath,
      outPath,
      quality: quality,
      minWidth: options.minWidth,
      minHeight: options.minHeight,
      keepExif: options.keepExif,
      format: options.format,
    );

    if (result == null) return null;
    return File(result.path);
  }

  static Future<bool> _looksLikeImage(String path) async {
    final ext = p.extension(path).toLowerCase();
    return <String>{
      '.jpg',
      '.jpeg',
      '.png',
      '.webp',
      '.heic',
      '.heif',
      '.gif',
      '.bmp',
    }.contains(ext);
  }

  static String _extFor(CompressFormat format) {
    switch (format) {
      case CompressFormat.jpeg:
        return '.jpg';
      case CompressFormat.png:
        return '.png';
      case CompressFormat.webp:
        return '.webp';
      case CompressFormat.heic:
        return '.heic';
      default:
        return '.jpg';
    }
  }
}
