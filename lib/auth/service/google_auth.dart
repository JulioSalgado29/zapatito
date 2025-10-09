import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:zapatito/services/local_storage.dart';

class GoogleAuthService {
  final auth = FirebaseAuth.instance;
  final googleSignIn = GoogleSignIn();

  // method to sign in using google
  Future<UserCredential?> trySilentSignIn() async {
  try {
    final googleUser = await googleSignIn.signInSilently();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await auth.signInWithCredential(credential);
  } catch (e) {
    print('Error en trySilentSignIn: $e');
    return null;
  }
}

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

      final userCredential = await auth.signInWithCredential(credential);

      // 🔹 Guardar datos del usuario localmente
      final user = userCredential.user;
      if (user != null) {
        await LocalStorageService.saveUserData(
          name: user.displayName ?? '',
          email: user.email ?? '',
          photoUrl: user.photoURL,
        );
      }

      return userCredential;
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

  Future<void> signOut() async {
    try {
      // Cierra sesión de Firebase
      await auth.signOut();

      // Cierra sesión de Google si hay un usuario conectado
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
      
      // 🔥 Elimina los datos guardados en local storage
      await LocalStorageService.clearUserData();


      print("Sesión cerrada correctamente.");
    } catch (e) {
      print('Error al cerrar sesión: $e');
    }
  }
}