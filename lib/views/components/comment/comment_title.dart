import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_instagram_clone/state/auth/providers/user_id_provider.dart';
import 'package:riverpod_instagram_clone/state/comments/models/comment.dart';
import 'package:riverpod_instagram_clone/state/comments/provides/delete_comment_provider.dart';
import 'package:riverpod_instagram_clone/state/user_info/providers/user_info_model_provider.dart';
import 'package:riverpod_instagram_clone/views/components/animations/small_error_animation_view.dart';
import 'package:riverpod_instagram_clone/views/components/constants/stings.dart';
import 'package:riverpod_instagram_clone/views/components/dialogs/alert_dialog_model.dart';
import 'package:riverpod_instagram_clone/views/components/dialogs/delte_dialog.dart';

class CommentTitle extends ConsumerWidget {
  final Comment comment;

  const CommentTitle({
    super.key,
    required this.comment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfo = ref.watch(
      userInfoModelProvider(
        comment.fromUserId,
      ),
    );

    return userInfo.when(
      data: (userInfo) {
        final currentUserId = ref.read(userIdProvider);
        return ListTile(
          trailing: currentUserId == comment.fromUserId
              ? IconButton(
                  icon: const Icon(
                    Icons.delete,
                  ),
                  onPressed: () async {
                    final shouldDelteComment = await displayDeleteDialog(
                      context,
                    );
                    if (shouldDelteComment) {
                      await ref
                          .read(deleteCommentProvider.notifier)
                          .deleteComment(commentId: comment.id);
                    }
                  },
                )
              : null,
          title: Text(userInfo.displayName),
          subtitle: Text(comment.comment),
        );
      },
      loading: () {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
      error: (error, stackTrace) {
        return const SmallErrorContentsAnimationView();
      },
    );

    return Container();
  }

  Future<bool> displayDeleteDialog(BuildContext context) =>
      const DeleteDialog(titleOfObjectToDelete: Strings.comment)
          .present(context)
          .then(
            (value) => value ?? false,
          );
}
