import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  const AuthService();

  User? get currentUser => FirebaseAuth.instance.currentUser;

  Future<void> signIn({required String email, required String password}) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => FirebaseAuth.instance.signOut();
}
