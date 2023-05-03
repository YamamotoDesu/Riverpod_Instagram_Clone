# riverpod_instagram_clone
https://www.youtube.com/watch?v=vtGCteFYs4M&t=16725s

<img width="300" alt="スクリーンショット 2023-04-24 11 26 49" src="https://user-images.githubusercontent.com/47273077/235820780-2ceef357-98e4-4661-96f7-d53cd6b8b24e.gif">


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

## Configure Firestore

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
}
```

lib/state/image_upload/models/file_type.dart
```dart
enum FileType {
  image,
  viedeo,
}
```

lib/state/posts/models/post_key.dart
```dart
import 'package:flutter/foundation.dart' show immutable;

@immutable 
class PostKey {
    static const userId = 'uid';
    static const message = 'message';
    static const createdAt = 'created_at';
    static const thumbnailUrl = 'thumbnail_url';
    static const fileUrl = 'file_url';
    static const fileType = 'file_type';
    static const fileName = 'file_name';
    static const aspectRatio = 'aspect_ratio';
    static const postSettings = 'post_settings';
    static const thumbnailStorageId = 'thumbnail_storage_id';
    static const originalStorageId = 'original_storage_id';

    const PostKey._();
}
```

lib/state/posts/models/post.dart
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:riverpod_instagram_clone/state/image_upload/models/file_type.dart';
import 'package:riverpod_instagram_clone/state/post_settings/models/post_setting.dart';
import 'package:riverpod_instagram_clone/state/posts/models/post_key.dart';

@immutable
class Post {
  final String postId;
  final String userId;
  final String message;
  final DateTime createdAt;
  final String thumbnailUrl;
  final String fileUrl;
  final FileType fileType;
  final String fileName;
  final double aspectRatio;
  final String thumbnailStorageId;
  final String originalStorageId;
  final Map<PostSetting, bool> postSettings;

  Post({
    required this.postId,
    required Map<String, dynamic> json,
  })  : userId = json[PostKey.userId],
        message = json[PostKey.message],
        createdAt = (json[PostKey.createdAt] as Timestamp).toDate(),
        thumbnailUrl = json[PostKey.thumbnailUrl],
        fileUrl = json[PostKey.fileUrl],
        fileType = FileType.values.firstWhere(
          (fileType) => fileType.name == json[PostKey.fileType],
          orElse: () => FileType.image,
        ),
        fileName = json[PostKey.fileName],
        aspectRatio = json[PostKey.aspectRatio],
        thumbnailStorageId = json[PostKey.thumbnailStorageId],
        originalStorageId = json[PostKey.originalStorageId],
        postSettings = {
          for (final entry in json[PostKey.postSettings].entries)
            PostSetting.values.firstWhere(
              (element) => element.storageKey == entry.key,
            ): entry.value,
        };

  bool get allowLilkes => postSettings[PostSetting.allowLikes] ?? false;
  bool get allowComments => postSettings[PostSetting.allowLikes] ?? false;
}
```

lib/state/post_settings/models/post_setting.dart
```dart
import 'package:riverpod_instagram_clone/state/post_settings/constants/constants.dart';

enum PostSetting {
  allowLikes(
    title: Constants.allowLikesTitle,
    description: Constants.allowLikesDescription,
    storageKey: Constants.allowLikesStorageKey,
  ),

  allowComments(
    title: Constants.allowCommentsTitle,
    description: Constants.allowCommentsDescription,
    storageKey: Constants.allowCommentsStorageKey,
  );

  final String title;
  final String description;
  final String storageKey;
  const PostSetting({
    required this.title,
    required this.description,
    required this.storageKey,
  });
}

```

lib/views/tabs/user_posts/user_posts_view.dart
```dart
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
```

## Inplements Main View

<img width="300" alt="スクリーンショット 2023-04-23 8 36 00" src="https://user-images.githubusercontent.com/47273077/233811934-a48deae7-b474-47ad-a150-b675813e47ac.png">

```dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_instagram_clone/state/auth/providers/auth_state_provider.dart';
import 'package:riverpod_instagram_clone/views/components/dialogs/alert_dialog_model.dart';
import 'package:riverpod_instagram_clone/views/components/dialogs/logout_dialog.dart';
import 'package:riverpod_instagram_clone/views/constants/strings.dart';
import 'package:riverpod_instagram_clone/views/tabs/user_posts/user_posts_view.dart';

class MainView extends ConsumerStatefulWidget {
  const MainView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MainViewState();
}

class _MainViewState extends ConsumerState<MainView> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
          appBar: AppBar(
            title: const Text(
              Strings.appName,
            ),
            actions: [
              IconButton(
                icon: const FaIcon(
                  FontAwesomeIcons.film,
                ),
                onPressed: () async {},
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_photo_alternate_outlined,
                ),
                onPressed: () async {},
              ),
              IconButton(
                icon: const Icon(
                  Icons.logout,
                ),
                onPressed: () async {
                  final shouldLogOut = await const LogoutDialog()
                      .present(context)
                      .then((value) => value ?? false);
                  if (shouldLogOut) {
                    await ref.read(authStateProvider.notifier).logOut();
                  }
                },
              ),
            ],
            bottom: const TabBar(
              tabs: [
                Tab(
                  icon: Icon(
                    Icons.person,
                  ),
                ),
                Tab(
                  icon: Icon(
                    Icons.search,
                  ),
                ),
                Tab(
                  icon: Icon(
                    Icons.home,
                  ),
                ),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              UserPostsView(),
              UserPostsView(),
              UserPostsView(),
            ],
          )),
    );
  }
}
```

lib/views/tabs/user_posts/user_posts_view.dart
```dart
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
```

## Show Alert Dialog

<img width="300" alt="スクリーンショット 2023-04-23 8 36 32" src="https://user-images.githubusercontent.com/47273077/233811944-e19b847b-ef75-4adb-8523-94e2d83a9844.png">

lib/views/components/dialogs/alert_dialog_model.dart
```dart
import 'package:flutter/material.dart';

@immutable
class AlertDialogModel<T> {
  final String title;
  final String message;
  final Map<String, T> buttons;

  const AlertDialogModel({
    required this.title,
    required this.message,
    required this.buttons,
  });
}

extension Present<T> on AlertDialogModel<T> {
  Future<T?> present(BuildContext context) {
    return showDialog<T>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: buttons.entries.map((entry) {
              return TextButton(
                child: Text(
                  entry.key,
                ),
                onPressed: () => Navigator.of(context).pop(
                  entry.value,
                ),
              );
            }).toList(),
          );
        });
  }
}
```

lib/views/components/dialogs/logout_dialog.dart
```dart
import 'package:flutter/foundation.dart' show immutable;
import 'package:riverpod_instagram_clone/views/components/constants/stings.dart';
import 'package:riverpod_instagram_clone/views/components/dialogs/alert_dialog_model.dart';

@immutable
class LogoutDialog extends AlertDialogModel<bool> {
  const LogoutDialog()
      : super(
          title: Strings.logOut,
          message: Strings.areYouSureThatYouWantToLogOutOfTheApp,
          buttons: const {
            Strings.cancel: false,
            Strings.logOut: true,
          },
        );
}
```

lib/views/main/main_view.dart
```dart
               IconButton(
                icon: const Icon(
                  Icons.logout,
                ),
                onPressed: () async {
                  final shouldLogOut = await const LogoutDialog()
                      .present(context)
                      .then((value) => value ?? false);
                  if (shouldLogOut) {
                    await ref.read(authStateProvider.notifier).logOut();
                  }
                },
              ),
```
 
## Upload Image 

<img width="300" alt="スクリーンショット 2023-04-24 11 26 49" src="https://user-images.githubusercontent.com/47273077/233886126-2b7b0b22-734b-48c8-91a2-9dcd84e34cd3.gif">

<img width="300" alt="スクリーンショット 2023-04-24 11 29 25" src="https://user-images.githubusercontent.com/47273077/233886312-55556a22-95dc-420e-900e-a93b2f11ba3a.png">

lib/views/main/main_view.dart
```dart
            actions: [
              IconButton(
                icon: const FaIcon(
                  FontAwesomeIcons.film,
                ),
                onPressed: () async {
                  final videoFile =
                      await ImagePickerHelper.pickVideoFromGallery();

                  if (videoFile == null) {
                    return;
                  }

                  ref.refresh(postSettingsProvider);

                  if (!mounted) {
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateNewPostView(
                        fileToPost: videoFile,
                        fileType: FileType.video,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_photo_alternate_outlined,
                ),
                onPressed: () async {
                  final imageFile =
                      await ImagePickerHelper.pickImageFromGallery();

                  if (imageFile == null) {
                    return;
                  }

                  ref.refresh(postSettingsProvider);

                  if (!mounted) {
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateNewPostView(
                        fileToPost: imageFile,
                        fileType: FileType.image,
                      ),
                    ),
                  );
                },
              ),
```

lib/views/create_new_post/create_new_post_view.dart
```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_instagram_clone/state/auth/providers/user_id_provider.dart';
import 'package:riverpod_instagram_clone/state/image_upload/models/file_type.dart';
import 'package:riverpod_instagram_clone/state/image_upload/models/thumbnail_request.dart';
import 'package:riverpod_instagram_clone/state/image_upload/provider/image_uploader_provider.dart';
import 'package:riverpod_instagram_clone/state/post_settings/models/post_setting.dart';
import 'package:riverpod_instagram_clone/state/post_settings/providers/post_settings_provider.dart';
import 'package:riverpod_instagram_clone/views/components/file_thumbnail_view.dart';
import 'package:riverpod_instagram_clone/views/constants/strings.dart';

class CreateNewPostView extends StatefulHookConsumerWidget {
  final File fileToPost;
  final FileType fileType;
  const CreateNewPostView({
    required this.fileToPost,
    required this.fileType,
    super.key,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CreateNewPostViewState();
}

class _CreateNewPostViewState extends ConsumerState<CreateNewPostView> {
  @override
  Widget build(BuildContext context) {
    final thumbnailRequest = ThumnnailRequest(
      file: widget.fileToPost,
      fileType: widget.fileType,
    );

    final postSettings = ref.watch(postSettingsProvider);
    final postController = useTextEditingController();
    final isPostButtonEnabled = useState(false);
    useEffect(() {
      void listner() {
        isPostButtonEnabled.value = postController.text.isNotEmpty;
      }

      postController.addListener(listner);

      return () {
        postController.removeListener(listner);
      };
    }, [postController]);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          Strings.createNewPost,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.send),
            onPressed: isPostButtonEnabled.value
                ? () async {
                    final userId = ref.read(
                      userIdProvider,
                    );
                    if (userId == null) {
                      return;
                    }
                    final message = postController.text;
                    final isUploaded =
                        await ref.read(imageUploadProvider.notifier).upload(
                              file: widget.fileToPost,
                              fileType: widget.fileType,
                              message: message,
                              postSettings: postSettings,
                              userId: userId,
                            );

                    if (isUploaded && mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                : null,
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FileThumbnailView(
              thumbnailRequest: thumbnailRequest,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: Strings.pleaseWriteYourMessageHere,
                ),
                autofocus: true,
                maxLength: null,
                controller: postController,
              ),
            ),
            ...PostSetting.values.map(
              (postSetting) => ListTile(
                title: Text(postSetting.title),
                subtitle: Text(postSetting.description),
                trailing: Switch(
                  value: postSettings[postSetting] ?? false,
                  onChanged: (isOn) {
                    ref.read(postSettingsProvider.notifier).setSetting(
                          postSetting,
                          isOn,
                        );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

lib/views/components/file_thumbnail_view.dart
```dart
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
```

lib/state/providers/is_loading_provider.dart
```dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_instagram_clone/state/auth/providers/auth_state_provider.dart';
import 'package:riverpod_instagram_clone/state/image_upload/provider/image_uploader_provider.dart';

final isLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  final isUploadingImage = ref.watch(imageUploadProvider);

  return authState.isLoading;
});
```

lib/state/post_settings/providers/post_settings_provider.dart
```dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_instagram_clone/state/post_settings/models/post_setting.dart';
import 'package:riverpod_instagram_clone/state/post_settings/notifiers/post_settings_notifier.dart';

final postSettingsProvider =
    StateNotifierProvider<PostSettingNotifier, Map<PostSetting, bool>>(
  (ref) => PostSettingNotifier(),
);

```

lib/state/post_settings/notifiers/post_settings_notifier.dart
```dart
import 'dart:collection';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_instagram_clone/state/post_settings/models/post_setting.dart';

class PostSettingNotifier extends StateNotifier<Map<PostSetting, bool>> {
  PostSettingNotifier()
      : super(
          UnmodifiableMapView(
            {
              for (final setting in PostSetting.values) setting: true,
            },
          ),
        );

  void setSetting(
    PostSetting setting,
    bool value,
  ) {
    final existingValue = state[setting];
    if (existingValue == null || existingValue == value) {
      return;
    }
    state = Map.unmodifiable(
      Map.from(state)..[setting] = value,
    );
  }
}
```
