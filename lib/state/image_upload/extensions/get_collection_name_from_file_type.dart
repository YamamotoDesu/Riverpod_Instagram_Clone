import 'package:riverpod_instagram_clone/state/image_upload/models/file_type.dart';

extension CollectionName on FileType {
  String getCollectionName() {
    switch (this) {
      case FileType.image:
        return 'images';
      case FileType.video:
        return 'videos';
    }
  }
}