import 'package:appwrite/appwrite.dart';

class AuthRepository {
  final Account account;

  AuthRepository(this.account);

  Future<void> createAccount({required String email, required String password, required String name}) async {
    await account.create(userId: ID.unique(), email: email, password: password, name: name);
  }

  Future<void> login({required String email, required String password}) async {
    await account.createEmailPasswordSession(email: email, password: password);
  }

  Future<void> logout() async {
    await account.deleteSession(sessionId: 'current');
  }

  Future<bool> isLoggedIn() async {
    try {
      await account.get();
      return true;
    } catch (_) {
      return false;
    }
  }
}
