import 'package:riverpod_instagram_clone/views/components/animations/lottie_animation_view.dart';
import 'package:riverpod_instagram_clone/views/components/animations/models/lottie_animation.dart';

class ErrorContentsAnimationView extends LottieAnimationView {
  const ErrorContentsAnimationView({super.key})
      : super(
          animation: LottieAnimation.error,
        );
}
