import 'dart:io';

import 'package:flutter/foundation.dart' show immutable;
import 'package:riverpod_instagram_clone/state/image_upload/models/file_type.dart';

@immutable
class ThumnnailRequest {
  final File file;
  FileType fileType;

  ThumnnailRequest({
    required this.file,
    required this.fileType,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThumnnailRequest &&
          runtimeType == other.runtimeType &&
          file == other.file &&
          fileType == other.fileType;

  @override
  int get hashCode => Object.hashAll(
        [
          runtimeType,
          file,
          fileType,
        ],
      );
}
