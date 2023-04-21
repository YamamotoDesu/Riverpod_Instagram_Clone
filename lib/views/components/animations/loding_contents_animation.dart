import 'package:riverpod_instagram_clone/views/components/animations/lottie_animation_view.dart';
import 'package:riverpod_instagram_clone/views/components/animations/models/lottie_animation.dart';

class LoadingContentsAnimationView extends LottieAnimationView {
  const LoadingContentsAnimationView({super.key})
      : super(
          animation: LottieAnimation.loading,
        );
}
