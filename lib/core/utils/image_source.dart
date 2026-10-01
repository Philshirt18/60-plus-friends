import 'dart:io';

import 'package:flutter/material.dart';

/// Resolves a stored photo reference into an [ImageProvider].
///
/// Supports three forms so seeded assets, locally-picked files, and remote
/// (Firebase Storage) URLs all work through one path:
///   - `asset://assets/images/foo.png` -> AssetImage
///   - `file:///path/to/photo.jpg`      -> FileImage (locally picked)
///   - `https://...`                    -> NetworkImage
ImageProvider? imageProviderFor(String? ref) {
  if (ref == null || ref.isEmpty) return null;
  const assetPrefix = 'asset://';
  const filePrefix = 'file://';
  if (ref.startsWith(assetPrefix)) {
    return AssetImage(ref.substring(assetPrefix.length));
  }
  if (ref.startsWith(filePrefix)) {
    return FileImage(File(ref.substring(filePrefix.length)));
  }
  return NetworkImage(ref);
}
