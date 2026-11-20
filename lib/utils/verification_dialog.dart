// utils/overlay_helper.dart
import 'package:tarlan_bank/controllers/verification_controller.dart';
import 'package:tarlan_bank/views/shared/app_snack_bar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';

Future<bool> showEmailConfirmationDialog({
  required String email,
  required BuildContext context,
  VerificationController? controller, // optional – defaults to Get.find()
}) async {
  final ctrl = controller ?? Get.find<VerificationController>();
  final theme = Theme.of(context);
  final size = MediaQuery.of(Get.context!).size;

  // ---- 1️⃣ Send the code -----------------------------------------------
  try {
    await ctrl.sendCode(email);
  } catch (e) {
    if (context?.mounted == true) {
      showAppSnackBar(
        context!,
        endPositionOffset: 1,
        title: 'Ошибка',
        message: 'Не удалось отправить код',
      );
    }
    return false;
  }

  // ---- 2️⃣ Show the dialog -----------------------------------------------
  final TextEditingController codeCtrl = TextEditingController();
  bool verified = false;

  await Get.dialog<void>(
    AlertDialog(
      title:
          Text('Введите код подтверждения', style: theme.textTheme.titleLarge),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: codeCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: theme.textTheme.titleLarge,
            decoration: InputDecoration(
              labelText: 'Код подтверждения',
              hintText: '000000',
              prefixIcon: const Icon(Icons.security),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            if (context?.mounted == true) {
              Navigator.of(context!).pop();
            } else {
              Get.back();
            }
          },
          style: theme.textButtonTheme.style,
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: () async {
            final code = codeCtrl.text.trim();
            if (code.length != 6) {
              if (context?.mounted == true) {
                showAppSnackBar(
                  context!,
                  endPositionOffset: 1,
                  title: 'Ошибка',
                  message: 'Код должен быть из 6 цифр',
                );
              }
              return;
            }

            try {
              final result = await ctrl.verifyRemoteCode(
                code,
                email,
                false,
              );

              if (result['message'] == 'Code verified successfully') {
                verified = true;

                if (context?.mounted == true) {
                  Navigator.of(context!).pop();
                } else {
                  Get.back();
                }
              } else if (result['error'] != null) {
                if (context?.mounted == true) {
                  showAppSnackBar(
                    context!,
                    endPositionOffset: 1,
                    title: 'Ошибка',
                    message: 'Неверный код',
                  );
                }
              }
            } catch (_) {
              if (context?.mounted == true) {
                showAppSnackBar(
                  context!,
                  endPositionOffset: 1,
                  title: 'Ошибка',
                  message: 'Не удалось проверить код. Попробуйте снова',
                );
              }
            }
          },
          style: theme.textButtonTheme.style,
          child: const Text('Подтвердить'),
        ),
      ],
    ),
  );

  return verified;
}
