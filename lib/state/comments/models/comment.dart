
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_instagram_clone/state/comments/typedefs/comment_id.dart';
import 'package:riverpod_instagram_clone/state/constants/firebase_field_name.dart';
import 'package:riverpod_instagram_clone/state/posts/typedefs/post_id.dart';
import 'package:riverpod_instagram_clone/state/posts/typedefs/user_id.dart';

@immutable
class Comment {
  final CommentId id;
  final String comment;
  final DateTime createdAt;
  final UserId fromUserId;
  final PostId postId;

  Comment(Map<String, dynamic> json, {required this.id}) :
    comment = json[FirebaseFieldName.comment],
    createdAt = (json[FirebaseFieldName.createdAt] as Timestamp).toDate(),
    fromUserId = json[FirebaseFieldName.userId],
    postId = json[FirebaseFieldName.postId];

    @override
    bool operator ==(Object other) {
      if (identical(this, other)) return true;
      return other is Comment &&
        other.id == id &&
        other.comment == comment &&
        other.createdAt == createdAt &&
        other.fromUserId == fromUserId &&
        other.postId == postId;
    }

    @override
    int get hashCode {
      return id.hashCode ^
        comment.hashCode ^
        createdAt.hashCode ^
        fromUserId.hashCode ^
        postId.hashCode;
    }
}