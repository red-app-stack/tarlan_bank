import 'dart:async';

import 'package:tarlan_bank/controllers/verification_controller.dart';
import 'package:tarlan_bank/services/auth_service.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

enum LoginStage { phone, email, verification, fullName, password }

class LoginController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final AuthService _authService = Get.find();
  final VerificationController _verificationController = Get.find();

  final phone = TextEditingController();
  final email = TextEditingController();
  final code = TextEditingController();
  final fullName = TextEditingController();
  final password = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final phoneFocus = FocusNode();
  final emailFocus = FocusNode();
  final codeFocus = FocusNode();
  final fullNameFocus = FocusNode();
  final passwordFocus = FocusNode();
  final Rx<bool> isPasswordVisible = false.obs;

  final stage = LoginStage.phone.obs;
  final isLoading = false.obs;
  final _errorMessage = ''.obs;
  final Map<dynamic, dynamic> args = Get.arguments as Map;

  String? getErrorForStage(LoginStage stage) {
    return _errorMessage.value.isNotEmpty && this.stage.value == stage
        ? _errorMessage.value
        : null;
  }

  void clearErrorMessage() {
    _errorMessage.value = '';
  }

  final obfuscatedEmail = Rx<String?>(null);
  final userFullName = Rx<String?>(null);

  RxInt get countdownSeconds => _verificationController.remainingSeconds;
  RxBool get canResendCode => _verificationController.canResend;

  late AnimationController animationController;
  late Animation<double> fadeAnimation;

  String get cleanPhone => phone.text.replaceAll(RegExp(r'\D'), '');

  @override
  void onInit() {
    super.onInit();
    animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    fadeAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      phoneFocus.requestFocus();
    });
  }

  void focusNext(FocusNode current) {
    if (current == phoneFocus) {
      emailFocus.requestFocus();
    } else if (current == emailFocus) {
      codeFocus.requestFocus();
    } else if (current == codeFocus) {
      fullNameFocus.requestFocus();
    } else if (current == fullNameFocus) {
      passwordFocus.requestFocus();
    }
  }

  void nextStage() {
    final currentIndex = stage.value.index;
    if (currentIndex < LoginStage.values.length - 1) {
      stage.value = LoginStage.values[currentIndex + 1];
      // ✅ Only animate forward, no reverse
      animationController.forward(from: 0);
    }
  }

  void previousStage() {
    final currentIndex = stage.value.index;
    if (currentIndex > 0) {
      stage.value = LoginStage.values[currentIndex - 1];
      // ✅ Immediately jump, no fade-out (looks cleaner when going back)
      animationController.value = 1.0; // reverse();
    }
    clearErrorMessage();
  }

  Future<void> submitPhone() async {
    if (!_validatePhone()) return;

    isLoading.value = true;
    clearErrorMessage();

    try {
      phoneFocus.unfocus();
      final result =
          await _authService.checkUserExistence(phoneNumber: cleanPhone);

      if (result['exists']) {
        obfuscatedEmail.value = result['user']['email'];
        nextStage();
      } else {
        obfuscatedEmail.value = null;
        nextStage();
      }
    } catch (e) {
      _errorMessage.value = 'Не удалось проверить номер: ${e.toString()}';
    } finally {
      isLoading.value = false;
      focusNext(phoneFocus);
    }
  }

  Future<void> submitEmail() async {
    if (!_validateEmail()) return;

    isLoading.value = true;
    clearErrorMessage();

    try {
      emailFocus.unfocus();
      if (obfuscatedEmail.value != null) {
        final isValid = await _authService.verifyPartialEmail(
          enteredEmail: email.text,
          obfuscatedEmail: obfuscatedEmail.value!,
        );
        if (!isValid) {
          _errorMessage.value = 'Email не совпадает';
          return;
        }
      }

      await sendVerificationCode();
    } catch (e) {
      _errorMessage.value = 'Ошибка: ${e.toString()}';
    } finally {
      isLoading.value = false;
      nextStage();
    }
  }

  Future<void> sendVerificationCode() async {
    isLoading.value = true;
    try {
      await _verificationController.sendCode(email.text);
    } catch (e) {
      _errorMessage.value = 'Не удалось отправить код: ${e.toString()}';
    } finally {
      isLoading.value = false;
      focusNext(emailFocus);
    }
  }

  Future<void> submitVerificationCode() async {
    if (!_validateCode()) return;

    isLoading.value = true;
    clearErrorMessage();

    try {
      codeFocus.unfocus();
      final result = await _verificationController.verifyRemoteCode(
        code.text,
        email.text,
        obfuscatedEmail.value != null,
      );

      print(result);

      // ✅ Parse server response correctly
      if (result['message'] == 'Code verified successfully') {
        userFullName.value = result['userData'];
        if (userFullName.value != null) {
          fullName.text = userFullName.value ?? '';
          submitFullName();
          nextStage();
        } else {
          nextStage();
          focusNext(codeFocus);
        }
      } else if (result['error'] == 'Invalid verification code') {
        final remaining = result['remainingAttempts'] ?? 0;
        _errorMessage.value = remaining > 0
            ? 'Неверный код. Осталось попыток: $remaining'
            : 'Превышено количество попыток';

        // Clear code for retry
        code.clear();
        codeFocus.requestFocus();
      } else {
        _errorMessage.value = result['error'] ?? 'Ошибка проверки';
        codeFocus.requestFocus();
      }
    } catch (e) {
      _errorMessage.value = 'Ошибка соединения. Попробуйте снова';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitFullName() async {
    if (!_validateFullName()) return;
    nextStage();
    focusNext(fullNameFocus);
  }

  Future<void> submitPassword() async {
    if (!_validatePassword()) return;

    isLoading.value = true;
    try {
      passwordFocus.unfocus();
      if (obfuscatedEmail.value != null) {
        await _authService.login(email: email.text, password: password.text);
        nextStage();
      } else {
        await _authService.register(
          email: email.text,
          phoneNumber: cleanPhone,
          fullName: fullName.text,
          password: password.text,
        );
      }

      _navigateToDestination();
    } catch (e) {
      print(e.toString());
      _errorMessage.value = obfuscatedEmail.value != null
          ? 'Ошибка входа. Неверный логин или пароль.'
          : 'Ошибка регистрации.';
      passwordFocus.requestFocus();
    } finally {
      isLoading.value = false;
    }
  }

  void _navigateToDestination() {
    Get.offNamed(
      '/codeEntering',
      arguments: {
        'isCreatingCode': obfuscatedEmail.value != null,
        'targetRoute': args['targetRoute'],
      },
    );
  }

  bool _validatePhone() {
    if (cleanPhone.length != 10) {
      _errorMessage.value = 'Введите корректный номер';
      return false;
    }
    return true;
  }

  bool _validateEmail() {
    if (!GetUtils.isEmail(email.text)) {
      _errorMessage.value = 'Введите корректный email';
      return false;
    }
    return true;
  }

  bool isFullName(String value) {
    final regex = RegExp(r"^[a-zA-Zа-яА-Я]+(?:[-'\s][a-zA-Zа-яА-Я]+){2,}$");
    return regex.hasMatch(value) && value.trim().split(' ').length >= 2;
  }

  bool _validateFullName() {
    if (!isFullName(fullName.text)) {
      _errorMessage.value = 'Введите фамилию, имя и отчество';
      return false;
    }
    clearErrorMessage();
    return true;
  }

  bool _validateCode() {
    if (code.text.length != 6) {
      _errorMessage.value = 'Код должен быть 6 цифр';
      return false;
    }
    return true;
  }

  bool _validatePassword() {
    if (password.text.length < 6) {
      _errorMessage.value = 'Пароль должен быть длиной минимум 6 символов';
      return false;
    }
    return true;
  }

  @override
  void onClose() {
    phone.dispose();
    email.dispose();
    code.dispose();
    fullName.dispose();
    password.dispose();
    animationController.dispose();
    phoneFocus.dispose();
    emailFocus.dispose();
    codeFocus.dispose();
    fullNameFocus.dispose();
    passwordFocus.dispose();
    super.onClose();
  }
}
