import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  final googleUser = await GoogleSignIn.instance.authenticate();
  final auth = googleUser.authentication;
  final idToken = auth.idToken;
  final accessToken = auth.accessToken;
}
