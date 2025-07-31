import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kronk/services/api_service/user_service.dart';

class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final UserService authApiService = UserService();

  Future<User?> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn.instance;

    try {
      // this will show account select snake bar
      final GoogleSignInAccount googleSignedInAccount = await googleSignIn.authenticate();

      final GoogleSignInAuthentication googleSignInAuthentication = googleSignedInAccount.authentication;
      log('🥳 googleSignedInAccount: ${googleSignedInAccount.toString()}');
      // create credential using sent by google
      // final AuthCredential credential = GoogleAuthProvider.credential(idToken: googleSignInAuthentication.idToken, accessToken: googleSignInAuthentication.accessToken);
      final AuthCredential credential = GoogleAuthProvider.credential(idToken: googleSignInAuthentication.idToken);

      // authenticate to firebase
      try {
        await _firebaseAuth.signInWithCredential(credential);
        log('🥳 User signed in with Google');
      } catch (e) {
        log('🥶 Failed to authenticate with Firebase: $e');
        return null;
      }

      // get firebase idToken from currentUser
      User? currentUser = _firebaseAuth.currentUser;
      String? firebaseUserIdToken = await currentUser?.getIdToken();

      log('🥳 firebaseUserIdToken: $firebaseUserIdToken');

      // send idToken and fetch user data from the server
      // User? user = await authApiService.fetchSocialAuth(firebaseUserIdToken: firebaseUserIdToken);
      // log("🥳 user: $user");
      // return user;
      return null;
    } catch (e) {
      log('🥶 an error occurred during Google Sign-In: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    final GoogleSignIn googleSignIn = GoogleSignIn.instance;

    try {
      // sign out in Firebase
      await _firebaseAuth.signOut();
      log('🥳 User signed out from Firebase.');

      // sign out in Google Sign-In
      await googleSignIn.signOut();
      log('🥳 User signed out from Google.');
    } catch (e) {
      log('🥶 An error occurred during sign out: $e');
    }
  }
}
