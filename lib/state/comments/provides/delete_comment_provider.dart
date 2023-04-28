import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_instagram_clone/state/comments/notifiers/delete_comment_notifier.dart';
import 'package:riverpod_instagram_clone/state/image_upload/type_defs/is_loading.dart';

final deleteCommentProvider =
    StateNotifierProvider<DeleteCommentStateNotifier, IsLoading>(
        (_) => DeleteCommentStateNotifier());
