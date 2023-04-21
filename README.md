# riverpod_instagram_clone
https://www.youtube.com/watch?v=vtGCteFYs4M&t=16725s

## Auth Impls

### Log In Page 
<img width="250" alt="スクリーンショット 2023-04-17 16 33 30" src="https://user-images.githubusercontent.com/47273077/232416029-7e692eb4-495a-4c8c-97c2-44e822426595.png"> 

### Google Login Flow
Google Dialog| Google Sign In | 
:-------------------------:|:-------------------------:
<img width="250" alt="スクリーンショット 2023-04-17 16 33 51" src="https://user-images.githubusercontent.com/47273077/232416100-15e21b85-aa6d-4861-97cf-7a7603a31f21.png"> | <img width="250" alt="スクリーンショット 2023-04-17 16 34 00" src="https://user-images.githubusercontent.com/47273077/232416134-2ef91af2-ea39-42f7-b384-7f0145da522b.png">

### FB Login Flow
FB Dialog| FB Sign In | 
:-------------------------:|:-------------------------:
<img width="250" alt="スクリーンショット 2023-04-17 16 35 01" src="https://user-images.githubusercontent.com/47273077/232416334-71654b55-8ba9-46e8-b8b2-541ef3d92337.png"> | <img width="250" alt="スクリーンショット 2023-04-17 16 35 09" src="https://user-images.githubusercontent.com/47273077/232416362-777abc84-2d7a-41e5-8f28-c522e1d0eaaa.png">

### Home Page
<img width="300" alt="スクリーンショット 2023-04-17 16 34 47" src="https://user-images.githubusercontent.com/47273077/232416287-7fbc3688-1170-43f0-bea9-1aad890d8395.png">


### Firestore Setup
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{collectionName}/{document=**} {
      allow read, update: if request.auth != null;
      allow create: if request.auth != null;
      allow delete: if request.auth != null && ((collectionName == "likes" || collectionName == "comments"|| collectionName == "posts"|| collectionName == "users") || request.auth.uid == resource.data.uid);
    }
  }
```

lib/main.dart
```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_instagram_clone/state/auth/backend/authenticator.dart';
import 'package:riverpod_instagram_clone/state/auth/providers/auth_state_provider.dart';
import 'package:riverpod_instagram_clone/state/auth/providers/is_logged_in_provider.dart';
import 'firebase_options.dart';

import 'dart:developer' as devtools show log;

extension Log on Object {
  void log() => devtools.log(toString());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.blueGrey,
          indicatorColor: Colors.blueGrey),
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: Consumer(
        builder: (context, ref, child) {
          final isLoggedIn = ref.watch(isLoggedInProvider);
          isLoggedIn.log();
          if (isLoggedIn) {
            return const MainView();
          } else {
            return const LoginView();
          }
        },
      ),
    );
  }
}

class MainView extends StatelessWidget {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Page'),
      ),
      body: Consumer(
        builder: (context, ref, child) => Column(
          children: [
            TextButton(
              onPressed: () async {
                await ref.read(authStateProvider.notifier).logOut();
              },
              child: const Text(
                'Log Out',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginView extends ConsumerWidget {
  const LoginView({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Page'),
      ),
      body: Column(
        children: [
          TextButton(
            onPressed: ref.read(authStateProvider.notifier).loginWithGoogle,
            child: const Text(
              'Sign In with Google',
            ),
          ),
          TextButton(
            onPressed: ref.read(authStateProvider.notifier).loginWithFacebook,
            child: const Text(
              'Sign In with Facebook',
            ),
          ),
        ],
      ),
    );
  }
}
```

lib/state/auth/backend/authenticator.dart
```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_instagram_clone/models/auth_result.dart';
import 'package:riverpod_instagram_clone/state/auth/constants/constants.dart';

import '../../posts/typedefs/user_id.dart';

class Authenticator {
  const Authenticator();

  User? get currentUser => FirebaseAuth.instance.currentUser;
  UserId? get userID => currentUser?.uid;
  bool get isAlreadyLoggedIn => userID != null;
  String get displayName => currentUser?.displayName ?? '';
  String? get email => currentUser?.email;

  Future<void> logOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    await FacebookAuth.instance.logOut();
  }

  Future<AuthResult> loginWithFacebook() async {
    final loginResult = await FacebookAuth.instance.login(permissions: [
      "public_profile"
    ]);
    final token = loginResult.accessToken?.token;
    if (token == null) {
      return AuthResult.aborted;
    }
    final oauthCredential = FacebookAuthProvider.credential(token);

    try {
      await FirebaseAuth.instance.signInWithCredential(
        oauthCredential,
      );
      return AuthResult.success;
    } on FirebaseAuthException catch (e) {
      final email = e.email;
      final credential = e.credential;
      if (e.code == Constants.accountExistsWithDifferentCredential &&
          email != null &&
          credential != null) {
        final providers =
            await FirebaseAuth.instance.fetchSignInMethodsForEmail(
          email,
        );
        if (providers.contains(Constants.googleCom)) {
          await loginWithGoogle();
          FirebaseAuth.instance.currentUser?.linkWithCredential(
            credential,
          );
          return AuthResult.success;
        }
      }
      return AuthResult.failure;
    }
  }

  Future<AuthResult> loginWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: [
        Constants.emailScope,
      ],
    );

    final signInAccount = await googleSignIn.signIn();
    if (signInAccount == null) {
      return AuthResult.aborted;
    }
    final googleAuth = await signInAccount.authentication;
    final oauthCredentials = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    try {
      await FirebaseAuth.instance.signInWithCredential(
        oauthCredentials,
      );
      return AuthResult.success;
    } catch (e) {
      return AuthResult.failure;
    }
  }
}
```

lib/state/auth/constants/auth_state.dart
```dart
// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/foundation.dart' show immutable;

import 'package:riverpod_instagram_clone/models/auth_result.dart';
import 'package:riverpod_instagram_clone/state/posts/typedefs/user_id.dart';

@immutable
class AuthState {
  final AuthResult? result;
  final bool isLoading;
  final UserId? userId;

  const AuthState({
    required this.result,
    required this.isLoading,
    required this.userId,
  });

  const AuthState.unknown()
      : result = null,
        isLoading = false,
        userId = null;

  AuthState copiedWithIsLoading(bool isLoading) => AuthState(
        result: result,
        isLoading: isLoading,
        userId: userId,
      );

  @override
  bool operator ==(covariant AuthState other) =>
      identical(this, other) ||
      result == other.result &&
          isLoading == other.isLoading &&
          userId == other.userId;

  @override
  int get hashCode => Object.hash(
        result,
        isLoading,
        userId,
      );
}
```

lib/state/auth/notifiers/auth_state_notifier.dart
```dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_instagram_clone/state/auth/constants/auth_state.dart';
import 'package:riverpod_instagram_clone/state/auth/notifiers/auth_state_notifier.dart';

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>(
  (_) => AuthStateNotifier(),
);
```

lib/state/auth/providers/is_logged_in_provider.dart
```dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_instagram_clone/state/auth/providers/auth_state_provider.dart';

import '../../../models/auth_result.dart';

final isLoggedInProvider = Provider<bool>((ref){
  final authProvider = ref.watch(authStateProvider);
  return authProvider.result == AuthResult.success;
});
```

lib/state/auth/providers/user_id_provider.dart
```dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_instagram_clone/state/posts/typedefs/user_id.dart';

import 'auth_state_provider.dart';

final userIdProvider = Provider<UserId?>(
  (ref) => ref.watch(authStateProvider).userId,
);
```

lib/state/constants/firebase_collection_name.dart
```dart
import 'package:flutter/material.dart' show immutable;

@immutable
class FirebaseCollectionName {
  static const thumbnails = 'thumbnails';
  static const comments = 'comments';
  static const likes = 'likes';
  static const posts = 'posts';
  static const users = 'users';
  const FirebaseCollectionName._();
}
```

lib/state/constants/firebase_field_name.dart
```dart
import 'package:flutter/material.dart' show immutable;

@immutable
class FirebaseFieldName {
  static const userId = 'uid';
  static const postId = 'post_id';
  static const comment = 'comment';
  static const createdAt = 'created_at';
  static const date = 'date';
  static const displayName = 'display_name';
  static const email = 'email';
  const FirebaseFieldName._();
}
```

lib/state/user_info/backend/user_info_storage.dart
```dart
import 'package:flutter/foundation.dart' show immutable;
import 'package:riverpod_instagram_clone/state/constants/firebase_collection_name.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_instagram_clone/state/user_info/models/user_info_payload.dart';

import '../../constants/firebase_field_name.dart';

@immutable
class UserInfoStorage {
  const UserInfoStorage();
  Future<bool> saveUserInfo({
    required String userId,
    required String displayName,
    required String? email,
  }) async {
    try {
      final userInfo = await FirebaseFirestore.instance
          .collection(FirebaseCollectionName.users)
          .where(FirebaseFieldName.userId, isEqualTo: userId)
          .limit(1)
          .get();

      if (userInfo.docs.isNotEmpty) {
        await userInfo.docs.first.reference.update({
          FirebaseFieldName.displayName: displayName,
          FirebaseFieldName.email: email ?? '',
        });
        return true;
      }

      final payload = UserInfoPayload(
        userId: userId,
        displayName: displayName,
        email: email,
      );
      await FirebaseFirestore.instance
          .collection(FirebaseCollectionName.users)
          .add(
            payload,
          );
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

lib/state/user_info/models/user_info_payload.dart
```dart
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
```

### Loading Screen
<img width="300" alt="スクリーンショット 2023-04-18 11 40 11" src="https://user-images.githubusercontent.com/47273077/232656466-c873da63-7a8f-4845-98fe-55cf085b7505.png">

lib/views/login/login_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_instagram_clone/state/auth/providers/auth_state_provider.dart';
import 'package:riverpod_instagram_clone/views/constants/app_colors.dart';
import 'package:riverpod_instagram_clone/views/login/divider_with_margin.dart';
import 'package:riverpod_instagram_clone/views/login/facebook_button.dart';
import 'package:riverpod_instagram_clone/views/login/google_button.dart';
import 'package:riverpod_instagram_clone/views/login/login_view_signup_link.dart';

import '../constants/strings.dart';

class LoginView extends ConsumerWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          Strings.appName,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(
                height: 40.0,
              ),
              Text(
                Strings.welcomeToAppName,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const DividerWithMargins(),
              Text(
                Strings.logIntoYourAccount,
                style: Theme.of(context).textTheme.subtitle1?.copyWith(
                      height: 1.5,
                    ),
              ),
              const SizedBox(
                height: 20.0,
              ),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.loginButtonColor,
                  foregroundColor: AppColors.loginButtonTextColor,
                ),
                onPressed:
                    ref.watch(authStateProvider.notifier).loginWithFacebook,
                child: const FacebookButton(),
              ),
              const SizedBox(
                height: 20.0,
              ),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.loginButtonColor,
                  foregroundColor: AppColors.loginButtonTextColor,
                ),
                onPressed:
                    ref.watch(authStateProvider.notifier).loginWithGoogle,
                child: const GoogleButton(),
              ),
              const DividerWithMargins(),
              const LoginViewSignupLink(),
            ],
          ),
        ),
      ),
    );
  }
}
```

lib/views/components/loading/loading_screen_controller.dart
```dart
import 'package:flutter/foundation.dart' show immutable;

typedef CloseLoadingScreen = bool Function();
typedef UpdateLoadingScreen = bool Function(String text);

@immutable
class LoadingScreenController {
  final CloseLoadingScreen close;
  final UpdateLoadingScreen update;

  const LoadingScreenController({
    required this.close,
    required this.update,
  });
}
```

lib/views/components/loading/loading_screen.dart
```dart

import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/stings.dart';
import 'loading_screen_controller.dart';

class LoadingScreen {
  LoadingScreen._sharedInstance();
  static final LoadingScreen _shared = LoadingScreen._sharedInstance();
  factory LoadingScreen.instance() => _shared;

  LoadingScreenController? controller;

  void show({
    required BuildContext context,
    String text = Strings.loading,
  }) {
    if (controller?.update(text) ?? false) {
      return;
    } else {
      controller = showOverlay(
        context: context,
        text: text,
      );
    }
  }

  void hide() {
    controller?.close();
    controller = null;
  }

  LoadingScreenController? showOverlay({
    required BuildContext context,
    required String text,
  }) {
    final textController = StreamController<String>();
    textController.add(text);

    final state = Overlay.of(context);
    if (state == null) {
      return null;
    }
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    final overlay = OverlayEntry(
      builder: (context) {
        return Material(
          color: Colors.black.withAlpha(150),
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: size.width * 0.8,
                maxHeight: size.height * 0.8,
                minWidth: size.width * 0.5,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      const CircularProgressIndicator(),
                      const SizedBox(height: 20),
                      StreamBuilder(
                        stream: textController.stream,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              snapshot.data as String,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.black),
                            );
                          } else {
                            return Container();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    state.insert(overlay);

    return LoadingScreenController(
      close: () {
        textController.close();
        overlay.remove();
        return true;
      },
      update: (text) {
        textController.add(text);
        return true;
      },
    );
  }
}
```

lib/main.dart
```dart
        builder: (_, ref, child) => Column(
          children: [
            TextButton(
              onPressed: () async {
                LoadingScreen.instance().show(
                  context: context,
                  text: 'Hello world',
                );
```

### Loading Screen with Provider

<img width="300" alt="スクリーンショット 2023-04-18 11 40 11" src="https://user-images.githubusercontent.com/47273077/232662540-f89e407e-2950-4648-9946-3a35a647d352.gif">

lib/main.dart
```dart
      home: Consumer(
        builder: (context, ref, child) {
          ref.listen<bool>(
            isLoadingProvider,
            (_, isLoading) {
              if (isLoading) {
                LoadingScreen.instance().show(
                  context: context,
                );
              } else {
                LoadingScreen.instance().hide();
              }
            },
          );

          final isLoggedIn = ref.watch(isLoggedInProvider);
          isLoggedIn.log();
          if (isLoggedIn) {
            return const MainView();
          } else {
            return const LoginView();
          }
        },
```

lib/state/auth/providers/is_logged_in_provider.dart
```dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_instagram_clone/state/auth/providers/auth_state_provider.dart';

import '../../../models/auth_result.dart';

final isLoggedInProvider = Provider<bool>((ref){
  final authProvider = ref.watch(authStateProvider);
  return authProvider.result == AuthResult.success;
});
```

### Login Screen
<img width="300" alt="スクリーンショット 2023-04-19 9 37 52" src="https://user-images.githubusercontent.com/47273077/232936387-f7efa43c-02a7-44ae-ac04-9a6a139e4b0a.png">

lib/views/login/divider_with_margin.dart
```dart
import 'package:flutter/material.dart';

class DividerWithMargins extends StatelessWidget {
  const DividerWithMargins({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        SizedBox(
          height: 20.0,
        ),
        Divider(),
        SizedBox(
          height: 20.0,
        ),
      ],
    );
  }
}
```

lib/views/login/facebook_button.dart
```dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:riverpod_instagram_clone/views/constants/app_colors.dart';
import 'package:riverpod_instagram_clone/views/constants/strings.dart';

class FacebookButton extends StatelessWidget {
  const FacebookButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            FontAwesomeIcons.facebook,
            color: AppColors.facebookColor,
          ),
          const SizedBox(
            width: 10.0,
          ),
          const Text(
            Strings.facebook,
          )
        ],
      ),
    );
  }
}
```

lib/views/login/google_button.dart
```dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:riverpod_instagram_clone/views/constants/app_colors.dart';
import 'package:riverpod_instagram_clone/views/constants/strings.dart';

class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            FontAwesomeIcons.google,
            color: AppColors.googleColor,
          ),
          const SizedBox(
            width: 10.0,
          ),
          const Text(
            Strings.google,
          )
        ],
      ),
    );
  }
}
```

lib/views/login/login_view_signup_link.dart
```dart
import 'package:flutter/material.dart';
import 'package:riverpod_instagram_clone/views/components/rich_text/base_text.dart';
import 'package:riverpod_instagram_clone/views/components/rich_text/rich_text_widget.dart';
import 'package:riverpod_instagram_clone/views/constants/strings.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginViewSignupLink extends StatelessWidget {
  const LoginViewSignupLink({super.key});

  @override
  Widget build(BuildContext context) {
    return RichTextWidget(
      styleForAll: Theme.of(context).textTheme.subtitle1?.copyWith(
            height: 1.5,
          ),
      texts: [
        BaseText.plain(
          text: Strings.dontHaveAnAccount,
        ),
        BaseText.plain(
          text: Strings.signUpOn,
        ),
        BaseText.link(
          text: Strings.facebook,
          onTapped: () {
            launchUrl(
              Uri.parse(
                Strings.facebookSignupUrl,
              ),
            );
          },
        ),
        BaseText.plain(
          text: Strings.orCreateAnAccountOn,
        ),
        BaseText.link(
          text: Strings.google,
          onTapped: () {
            launchUrl(
              Uri.parse(
                Strings.googleSignupUrl,
              ),
            );
          },
        ),
      ],
    );
  }
}
```

lib/views/components/rich_text/base_text.dart
```dart
// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/foundation.dart' show immutable, VoidCallback;
import 'package:flutter/material.dart' show TextStyle, Colors, TextDecoration;
import 'package:riverpod_instagram_clone/views/components/rich_text/link_text.dart';

@immutable
class BaseText {
  final String text;
  final TextStyle? style;

  const BaseText({
    required this.text,
    this.style,
  });

  factory BaseText.plain({
    required String text,
    TextStyle? style = const TextStyle(),
  }) =>
      BaseText(
        text: text,
        style: style,
      );

  
  factory BaseText.link({
    required String text,
    required VoidCallback onTapped,
    TextStyle? style = const TextStyle(
      color: Colors.blue,
      decoration: TextDecoration.underline,
    ),
  }) =>
      LinkText(
        text: text,
        onTapped: onTapped,
        style: style,
      );
}
```

lib/views/components/rich_text/link_text.dart
```dart
import 'package:flutter/foundation.dart' show immutable, VoidCallback;
import 'package:riverpod_instagram_clone/views/components/rich_text/base_text.dart';

@immutable
class LinkText extends BaseText {
  final VoidCallback onTapped;
  const LinkText({
    required super.text,
    required this.onTapped,
    super.style,
  });
}
```

lib/views/components/rich_text/rich_text_widget.dart
```dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_instagram_clone/views/components/rich_text/link_text.dart';

import 'base_text.dart';

class RichTextWidget extends StatelessWidget {
  final Iterable<BaseText> texts;
  final TextStyle? styleForAll;

  const RichTextWidget({
    super.key,
    required this.texts,
    this.styleForAll,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: texts.map((baseText) {
          if (baseText is LinkText) {
            return TextSpan(
              text: baseText.text,
              style: styleForAll?.merge(baseText.style),
              recognizer: TapGestureRecognizer()..onTap = baseText.onTapped,
            );
          } else {
            return TextSpan(
              text: baseText.text,
              style: styleForAll?.merge(baseText.style),
            );
          }
        }).toList(),
      ),
    );
  }
}
```

lib/extensions/string/as_html_color_to_color.dart
```dart
import 'package:flutter/material.dart';
import 'package:riverpod_instagram_clone/extensions/string/remove_all.dart';

extension AsHtmlColorToColor on String {
  Color htmlColorToColor() => Color(
        int.parse(
          removeAll(['0x', '#']).padLeft(8, 'ff'),
          radix: 16,
        ),
      );
}
```

lib/extensions/string/remove_all.dart
```dart
extension RemoveAll on String {
  String removeAll(Iterable<String> values) => values.fold(
        this,
        (result, value) => result.replaceAll(
          value,
          '',
        ),
      );
}
```

## Lottie Animation

lib/views/components/animations/models/lottie_animation.dart
```dart
enum LottieAnimation {
  dataNotFound(name: "data_not_found"),
  empty(name: "empty"),
  loading(name: "loading"),
  error(name: "error"),
  smallError(name: "small_error");

  final String name;
  const LottieAnimation({
    required this.name,
  });
}
```

lib/views/components/animations/lottie_animation_view.dart
```dart

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:riverpod_instagram_clone/views/components/animations/models/lottie_animation.dart';

class LottieAnimationView extends StatelessWidget {
  final LottieAnimation animation;
  final bool repeat;
  final bool reverse;

  const LottieAnimationView({
    super.key,
    required this.animation,
    this.repeat = true,
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) => Lottie.asset(
        animation.fullPath,
        reverse: reverse,
        repeat: repeat,
      );
}

extension GetFullPath on LottieAnimation {
  String get fullPath => 'assets/animations/$name.json';
}
```

lib/views/components/animations/data_not_found_animation.dart
```dart
import 'package:riverpod_instagram_clone/views/components/animations/lottie_animation_view.dart';
import 'package:riverpod_instagram_clone/views/components/animations/models/lottie_animation.dart';

class DataNotFoundAnimationView extends LottieAnimationView {
  const DataNotFoundAnimationView({super.key})
      : super(
          animation: LottieAnimation.dataNotFound,
        );
}
```

lib/views/components/animations/empty_content_with_text.dart
```dart
import 'package:flutter/material.dart';
import 'package:riverpod_instagram_clone/views/components/animations/empty_contents_animation.dart';

class EmptyContentWithTextAnimationView extends StatelessWidget {
  final String text;
  const EmptyContentWithTextAnimationView({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.white54),
            ),
          ),
          const EmptyContentsAnimationView(),
        ],
      ),
    );
  }
}
```

lib/views/components/animations/empty_contents_animation.dart
```dart
import 'package:riverpod_instagram_clone/views/components/animations/lottie_animation_view.dart';
import 'package:riverpod_instagram_clone/views/components/animations/models/lottie_animation.dart';

class EmptyContentsAnimationView extends LottieAnimationView {
  const EmptyContentsAnimationView({super.key})
      : super(
          animation: LottieAnimation.empty,
        );
}
```
