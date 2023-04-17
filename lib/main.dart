import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:riverpod_instagram_clone/state/auth/backend/authenticator.dart';
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
    MaterialApp(
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
      home: const HomePage(),
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Home Page'),
        ),
        body: Column(
          children: [
            TextButton(
              onPressed: () async {
                final result = await Authenticator().loginWithGoogle();
                result.log();
              },
              child: const Text(
                'Sign In with Google',
              ),
            ),
            TextButton(
              onPressed: () async {
                final result = await Authenticator().loginWithFacebook();
                result.log();
              },
              child: const Text(
                'Sign In with Facebook',
              ),
            ),
          ],
        ));
  }
}
