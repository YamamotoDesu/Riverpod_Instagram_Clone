import 'dart:collection' show MapView;

import 'package:flutter/foundation.dart' show immutable;
import 'package:riverpod_instagram_clone/state/posts/typedefs/user_id.dart';

import '../../constants/firebase_field_name.dart';

@immutable
class UserInfoPayload extends MapView<String, String> {
  UserInfoPayload({
    required UserId userId,
    required String? displayName,
    required String? email,
  }) : super(
          {
            FirebaseFieldName.userId: userId,
            FirebaseFieldName.displayName: displayName ?? '',
            FirebaseFieldName.email: email ?? '',
          },
        );
}
