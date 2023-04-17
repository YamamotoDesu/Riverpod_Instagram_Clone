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

