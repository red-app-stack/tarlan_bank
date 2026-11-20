import 'package:tarlan_bank/controllers/login_controller.dart';
import 'package:tarlan_bank/utils/themes/theme_extension.dart';
import 'package:tarlan_bank/views/shared/formatters.dart' show formatPhone;
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());

    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Obx(() => Stack(
                children: [
                  _buildContent(controller, context),
                  // if (controller.isLoading.value)
                  //   Material(
                  //     color: Colors.black.withValues(alpha: 0.4),
                  //     child: Center(
                  //       child: const Center(
                  //         child: CircularProgressIndicator(strokeWidth: 3),
                  //       ),
                  //     ),
                  //   ),
                ],
              )),
        ),
      ),
    );
  }

  Widget _buildContent(LoginController controller, BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Column(
      children: [
        _buildAppBar(controller, context),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPhoneStage(controller, theme),
                  _buildAnimatedStages(controller, theme),
                ],
              ),
            ),
          ),
        ),
        _buildActionButton(controller, context),
      ],
    );
  }

  Widget _buildAppBar(LoginController controller, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 12, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/ic_back.svg',
            width: 28,
            height: 28,
            colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.primary, BlendMode.srcIn),
          ),
          onPressed: () {
            if (controller.stage.value == LoginStage.phone) {
              Navigator.of(context).pop();
            } else {
              controller.previousStage();
            }
          },
        ),
      ),
    );
  }

  Widget _buildPhoneStage(
    LoginController controller,
    ThemeData theme,
  ) {
    return IgnorePointer(
      ignoring: controller.stage.value != LoginStage.phone,
      child: _buildTextField(
        theme: theme,
        textController: controller.phone,
        focusNode: controller.phoneFocus,
        keyboardType: TextInputType.phone,
        label: 'Номер телефона',
        hint: '(000) 000-00-00',
        prefixText: '+7 ',
        onChanged: (value) {
          controller.clearErrorMessage();
          final formattedValue = formatPhone(value);
          controller.phone.value = TextEditingValue(
            text: formattedValue,
            selection: TextSelection.collapsed(offset: formattedValue.length),
          );
        },
        errorText: controller.getErrorForStage(LoginStage.phone),
        validator: (value) =>
            controller.phone.text.length < 17 ? 'Введите полный номер' : null,
        onFieldSubmitted: () => controller.stage.value == LoginStage.phone
            ? controller.submitPhone()
            : controller.focusNext(controller.phoneFocus),
      ),
    );
  }

  Widget _buildAnimatedStages(LoginController controller, ThemeData theme) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEmailStage(controller, theme),
          _buildVerificationStage(controller, theme),
          _buildFullNameStage(controller, theme),
          _buildPasswordStage(controller, theme),
        ],
      ),
    );
  }

  Widget _buildEmailStage(LoginController controller, ThemeData theme) {
    return Obx(() {
      final isVisible = controller.stage.value.index >= LoginStage.email.index;
      if (!isVisible) return const SizedBox();

      return AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isVisible ? 1.0 : 0.0,
        child: IgnorePointer(
          ignoring: controller.stage.value != LoginStage.email,
          child: _buildTextField(
            theme: theme,
            textController: controller.email,
            focusNode: controller.emailFocus,
            keyboardType: TextInputType.emailAddress,
            label: controller.obfuscatedEmail.value != null
                ? 'Подтвердите почту'
                : 'Введите Email',
            hint: controller.obfuscatedEmail.value,
            prefixIcon: Icons.email,
            errorText: controller.getErrorForStage(LoginStage.email),
            validator: (value) =>
                !GetUtils.isEmail(value ?? '') ? 'Неверный email' : null,
            onFieldSubmitted: () => controller.stage.value == LoginStage.email
                ? controller.submitEmail()
                : controller.focusNext(controller.emailFocus),
          ),
        ),
      );
    });
  }

  Widget _buildVerificationStage(LoginController controller, ThemeData theme) {
    return Obx(() {
      final isVisible =
          controller.stage.value.index >= LoginStage.verification.index;
      if (!isVisible) return const SizedBox();

      return AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isVisible ? 1.0 : 0.0,
        child: IgnorePointer(
          ignoring: controller.stage.value != LoginStage.verification,
          child: Column(
            children: [
              _buildTextField(
                theme: theme,
                textController: controller.code,
                focusNode: controller.codeFocus,
                keyboardType: TextInputType.number,
                label: 'Код подтверждения',
                hint: '000000',
                maxLength: 6,
                prefixIcon: Icons.security,
                errorText: controller.getErrorForStage(LoginStage.verification),
                validator: (value) =>
                    value?.length != 6 ? 'Код из 6 цифр' : null,
                onFieldSubmitted: () =>
                    controller.stage.value == LoginStage.verification
                        ? controller.submitVerificationCode()
                        : controller.focusNext(controller.codeFocus),
              ),
              controller.stage.value == LoginStage.verification
                  ? Column(
                      children: [
                        const SizedBox(height: 12),
                        Center(child: _buildResendText(controller, theme)),
                      ],
                    )
                  : const SizedBox(),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildFullNameStage(LoginController controller, ThemeData theme) {
    return Obx(() {
      final isVisible =
          controller.stage.value.index >= LoginStage.fullName.index;
      if (!isVisible) return const SizedBox();

      return AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isVisible ? 1.0 : 0.0,
        child: IgnorePointer(
          ignoring: controller.stage.value != LoginStage.fullName ||
              controller.isFullName(controller.userFullName.value ?? ''),
          child: _buildTextField(
            theme: theme,
            textController: controller.fullName,
            focusNode: controller.fullNameFocus,
            label: 'Ваше ФИО',
            hint: 'Фамилия Имя Отчество',
            prefixIcon: Icons.person,
            errorText: controller.getErrorForStage(LoginStage.fullName),
            validator: (value) {
              if (!controller.isFullName(value ?? '')) {
                return 'Введите полное имя';
              }
              return null;
            },
            onFieldSubmitted: () =>
                controller.stage.value == LoginStage.fullName
                    ? controller.submitFullName()
                    : controller.focusNext(controller.fullNameFocus),
          ),
        ),
      );
    });
  }

  Widget _buildPasswordStage(LoginController controller, ThemeData theme) {
    return Obx(() {
      final isVisible =
          controller.stage.value.index >= LoginStage.password.index;
      if (!isVisible) return const SizedBox();

      return AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isVisible ? 1.0 : 0.0,
        child: IgnorePointer(
          ignoring: controller.stage.value != LoginStage.password,
          child: _buildTextField(
            theme: theme,
            textController: controller.password,
            focusNode: controller.passwordFocus,
            label: controller.userFullName.value != null
                ? 'Ваш пароль'
                : 'Придумайте пароль',
            prefixIcon: Icons.lock,
            suffixIcon: IconButton(
              icon: Icon(
                controller.isPasswordVisible.value
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () {
                controller.isPasswordVisible.value =
                    !controller.isPasswordVisible.value;
              },
            ),
            obscureText: !controller.isPasswordVisible.value,
            errorText: controller.getErrorForStage(LoginStage.password),
            validator: (value) => value!.length < 6
                ? 'Пароль должен быть длиной минимум 6 символов'
                : null,
            onFieldSubmitted: () => controller.submitPassword(),
          ),
        ),
      );
    });
  }

  Widget _buildTextField({
    required ThemeData theme,
    required TextEditingController textController,
    bool readOnly = false,
    required FocusNode focusNode,
    required String label,
    String? hint,
    String? prefixText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    int? maxLength,
    String? Function(String?)? validator,
    String? errorText,
    void Function()? onFieldSubmitted,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: textController,
        focusNode: focusNode,
        readOnly: readOnly,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLength: maxLength,
        onChanged: onChanged,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) => onFieldSubmitted?.call(),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: theme.textTheme.titleLarge?.copyWith(
              color: theme
                  .extension<Extra>()
                  ?.primaryText
                  ?.withValues(alpha: 0.5)),
          prefixText: prefixText,
          errorText: errorText,
          prefixStyle: theme.textTheme.titleLarge,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
          suffixIcon: suffixIcon,
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerLowest,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        style: theme.textTheme.titleLarge,
        validator: validator,
      ),
    );
  }

  Widget _buildResendText(LoginController controller, ThemeData theme) {
    return Obx(() => (!controller.canResendCode.value)
        ? Text(
            'Повторная отправка через ${controller.countdownSeconds.value} сек',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        : TextButton(
            onPressed: controller.sendVerificationCode,
            child: Text(
              'Отправить код повторно',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ));
  }

  Widget _buildActionButton(LoginController controller, BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: 16,
        left: 24,
        right: 24,
        top: 8,
      ),
      child: Obx(() => ElevatedButton(
            onPressed:
                controller.isLoading.value ? () {} : _getAction(controller),
            child: controller.isLoading.value
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onPrimary),
                  )
                : Text(
                    _getButtonText(controller),
                  ),
          )),
    );
  }

  VoidCallback? _getAction(LoginController controller) {
    switch (controller.stage.value) {
      case LoginStage.phone:
        return controller.submitPhone;
      case LoginStage.email:
        return controller.submitEmail;
      case LoginStage.verification:
        return controller.submitVerificationCode;
      case LoginStage.fullName:
        return controller.submitFullName;
      case LoginStage.password:
        return controller.submitPassword;
    }
  }

  String _getButtonText(LoginController controller) {
    switch (controller.stage.value) {
      case LoginStage.phone:
        return 'Продолжить';
      case LoginStage.email:
        return 'Отправить код';
      case LoginStage.verification:
        return 'Подтвердить';
      case LoginStage.fullName:
        return 'Продолжить';
      case LoginStage.password:
        return 'Завершить';
    }
  }
}
