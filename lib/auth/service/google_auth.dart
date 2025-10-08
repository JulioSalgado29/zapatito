import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final auth = FirebaseAuth.instance;
  final googleSignIn = GoogleSignIn();

  // method to sign in using google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await googleSignIn.signIn();

      // Si el usuario cancela, googleUser será null
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;

      // Validar que al menos uno de los tokens no sea null
      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        return null;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await auth.signInWithCredential(credential);
    } catch (e) {
      print('Error en signInWithGoogle: $e');
      return null;
    }
  }

  Future<User> isCurrentSignIn(User ?user) async {
    if (user != null) {
      assert(!user.isAnonymous);
      assert(await user.getIdToken() != null);
      final User currentUser = auth.currentUser!;
      assert(user.uid == currentUser.uid);
      print("User is signed in!");
      return user;
    } 
    else {
      print("No user is signed in.");
      throw Exception("No user is signed in.");
    }
  }
}
