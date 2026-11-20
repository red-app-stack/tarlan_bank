import 'dart:convert';
import '../models/user_model.dart';
import 'secure_store.dart';

class UserRepository {
  final SecureStore secureStore;
  UserModel? currentUser;

  UserRepository({required this.secureStore});

  Future<void> storeUser(UserModel user) async {
    currentUser = user;
    await secureStore.write('user_data', jsonEncode(user.toJson()));
  }

  Future<UserModel?> retrieveLocalUser() async {
    final data = await secureStore.read('user_data');
    if (data == null) return null;
    try {
      final user = UserModel.fromJson(jsonDecode(data));
      currentUser = user;
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAll() async => await secureStore.deleteAll();

  Future<void> clearUser() async => await secureStore.delete('user_data');
}
