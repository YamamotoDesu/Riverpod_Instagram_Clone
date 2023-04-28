import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_instagram_clone/state/constants/firebase_collection_name.dart';
import 'package:riverpod_instagram_clone/state/image_upload/type_defs/is_loading.dart';
import 'package:riverpod_instagram_clone/views/components/comment/comment_payload.dart';

class SendCommentNotifier extends StateNotifier<IsLoading> {
  SendCommentNotifier() : super(false);

  set isLoading(bool value) => state = value;

  Future<bool> sendComment({
    required String fromUserId,
    required String onPostId,
    required String comment,
  }) async {
    isLoading = true;

    final payload = CommentPayload(
      fromUserId: fromUserId,
      onPostId: onPostId,
      comment: comment,
    );

    try {
      await FirebaseFirestore
      .instance
      .collection(FirebaseCollectionName.comments)
      .add(payload);


      return true;
    } catch (_) {
      return false;
    } finally {
      isLoading = false;
    }
  }
}
