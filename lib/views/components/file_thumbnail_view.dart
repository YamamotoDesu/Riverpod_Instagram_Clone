import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_instagram_clone/state/image_upload/models/thumbnail_request.dart';
import 'package:riverpod_instagram_clone/state/image_upload/provider/thumbnail_provider.dart';
import 'package:riverpod_instagram_clone/views/components/animations/loding_contents_animation.dart';
import 'package:riverpod_instagram_clone/views/components/animations/small_error_animation_view.dart';

class FileThumbnailView extends ConsumerWidget {
  final ThumnnailRequest thumbnailRequest;

  const FileThumbnailView({
    required this.thumbnailRequest,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnail = ref.watch(
      thumbnailProvider(
        thumbnailRequest,
      ),
    );

    return thumbnail.when(
      data: (imageWithAspectRatio) {
        return AspectRatio(
          aspectRatio: imageWithAspectRatio.aspectRatio,
          child: imageWithAspectRatio.image,
        );
      },
      loading: () {
        return const LoadingContentsAnimationView();
      },
      error: (error, stackTrace) {
        return const SmallErrorContentsAnimationView();
      },
    );
  }
}
