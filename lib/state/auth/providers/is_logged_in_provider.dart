import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_instagram_clone/state/auth/providers/auth_state_provider.dart';

import '../../../models/auth_result.dart';

final isLoggedInProvider = Provider<bool>((ref){
  final authProvider = ref.watch(authStateProvider);
  return authProvider.result == AuthResult.success;
});