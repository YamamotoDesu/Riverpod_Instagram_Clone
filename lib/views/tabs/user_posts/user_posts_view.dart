import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_instagram_clone/state/posts/providers/user_posts_provider.dart';
import 'package:riverpod_instagram_clone/views/components/animations/empty_content_with_text.dart';
import 'package:riverpod_instagram_clone/views/components/animations/error_contents_animation.dart';
import 'package:riverpod_instagram_clone/views/components/animations/loding_contents_animation.dart';
import 'package:riverpod_instagram_clone/views/components/post/posts_grid_view.dart';

import '../../constants/strings.dart';

class UserPostsView extends ConsumerWidget {
  const UserPostsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(userPostsProvider);

    return RefreshIndicator(
      onRefresh: () {
        ref.refresh(userPostsProvider);
        return Future.delayed(const Duration(seconds: 1));
      },
      child: posts.when(
        data: (posts) {
          if (posts.isEmpty) {
            return const EmptyContentWithTextAnimationView(
              text: Strings.youHaveNoPosts,
            );
          } else {
            return PostsGridView(
              posts: posts,
            );
          }
        },
        error: (error, stackTrace) {
          return const ErrorContentsAnimationView();
        },
        loading: () {
          return const LoadingContentsAnimationView();
        },
      ),
    );
  }
}
