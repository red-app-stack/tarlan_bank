import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tarlan_bank/core/firebase/firestore_db.dart';

/// Audit record `face_verifications/{uid}`. No images or templates are ever
/// stored. The client can only write `passed` / `manual_requested`; a trusted
/// reviewer (Admin SDK) sets `approved` / `rejected`. See firestore.rules.
class FaceVerificationRepository {
  Future<void> record({
    required String uid,
    required String status, // passed | manual_requested
    required String method, // liveness | pin | support
    required String deviceId,
    int challenges = 0,
  }) {
    return tarlanFirestore().collection('face_verifications').doc(uid).set({
      'status': status,
      'method': method,
      'deviceId': deviceId,
      'challenges': challenges,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
