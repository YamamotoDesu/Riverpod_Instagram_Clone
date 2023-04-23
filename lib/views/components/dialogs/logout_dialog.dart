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
