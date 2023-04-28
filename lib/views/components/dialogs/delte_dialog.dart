
import 'package:flutter/foundation.dart';
import 'package:riverpod_instagram_clone/views/components/dialogs/alert_dialog_model.dart';

import '../constants/stings.dart';

@immutable
class DeleteDialog extends AlertDialogModel<bool> {
  const DeleteDialog({
    required String titleOfObjectToDelete,
  }) : super(
    title: '${Strings.delete} $titleOfObjectToDelete?',
    message: '${Strings.areYouSureYouWantToDeleteThis} $titleOfObjectToDelete?',
    buttons: const {
      Strings.cancel: false,
      Strings.delete: true,
    }
  );
}