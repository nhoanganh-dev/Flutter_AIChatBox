import 'package:chat_box/repos/supabase.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  final auth = SupabaseRepository.auth;

  Future<void> googleSignIn() async {
    final webClientId = dotenv.get('WEB_CLIENTID');

    final iosClientId = dotenv.get('IOS_CLIENTID');

    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: webClientId,
      clientId: iosClientId,
    );
    final googleUser = await googleSignIn.signIn();
    final googleAuth = await googleUser!.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null) {
      throw 'No Access Token found.';
    }
    if (idToken == null) {
      throw 'No ID Token found.';
    }

    await auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  Future<void> logout() async {
    await auth.signOut();
  }

  Future<User> getCurrentUser() async {
    final user = auth.currentUser;
    if (user != null) {
      return user;
    } else {
      throw 'No user found.';
    }
  }
}
