import 'package:get/get.dart';
import '../services/verification_service.dart';

class VerificationController extends GetxController {
  final VerificationService verification = Get.find<VerificationService>();

  RxBool isSendingCode = false.obs;
  RxBool codeSent = false.obs;
  RxBool canResend = true.obs;
  RxInt remainingSeconds = 0.obs;

  @override
  void onInit() {
    super.onInit();
    verification.countdownStream.listen((secs) {
      remainingSeconds.value = secs;
      canResend.value = secs <= 0;
    });
  }

  // --------------------------------------------------------------------
  Future<void> sendCode(String email) async {
    isSendingCode.value = true;
    try {
      await verification.sendCode(email);
      codeSent.value = true;
      canResend.value = false;
      startCountdown();
    } catch (_) {
      // handle errors via Get.snackbar or expose a message Rx
    } finally {
      isSendingCode.value = false;
    }
  }

  void startCountdown() {
    canResend.value = false;
    verification.startCountdown();
  }

  Future<bool> verifyAccessCode(String code) async {
    final localOk = await verification.verifyAccessCode(code);
    return localOk;
  }

  Future<void> storeHashedCode(String code) async {
    await verification.storeHashedCode(code);
  }

  Future<bool> accessCodeExists() async {
    return await verification.accessCodeExists();
  }

  @override
  void onClose() {
    verification.cancelCountdown();
    super.onClose();
  }

  Future<Map<String, dynamic>> verifyRemoteCode(
      String code, String email, bool exists) async {
    return await verification.verifyRemoteCode(code, email, exists);
  }
}
