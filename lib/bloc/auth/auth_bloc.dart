import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:eventmanager/services/navigation_service.dart'; // ⚠️ Consider if this is directly needed in the BLoC
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // ⚠️ Only needed for specific widgets, not core logic
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

// Events 🚀
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  // 🕵️ Emitted when the app starts or needs to check authentication status.
}

class SignInWithGooglePressed extends AuthEvent {
  // ➡️ Emitted when the user presses the "Sign in with Google" button.
}

class SignInWithApplePressed extends AuthEvent {
  // 🍎 Emitted when the user presses the "Sign in with Apple" button.
}

class SignOutRequested extends AuthEvent {
  // 👋 Emitted when the user requests to sign out.
}

// States 🚦
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  // 👶 Initial state of the authentication flow.
}

class AuthLoading extends AuthState {
  // ⏳ The authentication process is currently in progress.
}

class Authenticated extends AuthState {
  final User user;

  Authenticated(this.user);

  @override
  List<Object?> get props => [user];
  // ✅ User is successfully authenticated. Contains the User object.
}

class Unauthenticated extends AuthState {
  // 🚪 User is not authenticated.
}

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);

  @override
  List<Object?> get props => [message];
  // ❌ An error occurred during the authentication process. Contains the error message.
}

// BLoC ⚙️
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  // final NavigationService _navigationService; // ⚠️ Consider if BLoC should handle navigation directly

  AuthBloc()
    : _firebaseAuth = FirebaseAuth.instance,
      _googleSignIn = GoogleSignIn(),
      // _navigationService = NavigationService(), // ⚠️ Consider dependency injection
      super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<SignInWithGooglePressed>(
      _onSignInWithGooglePressed, // ✅ Corrected the type casting
    );
    on<SignInWithApplePressed>(_onSignInWithApplePressed);
    on<SignOutRequested>(_onSignOutRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('🔍 AuthCheckRequested event received.');
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      print('👤 User is currently signed in: ${user.uid}');
      emit(Authenticated(user));
      print('✅ Emitted Authenticated state.');
    } else {
      print('🚪 No user currently signed in.');
      emit(Unauthenticated());
      print('🚫 Emitted Unauthenticated state.');
    }
  }

  Future<void> _onSignInWithGooglePressed(
    SignInWithGooglePressed event,
    Emitter<AuthState> emit,
  ) async {
    print('➡️ SignInWithGooglePressed event received.');
    try {
      print('⏳ Emitting AuthLoading state.');
      emit(AuthLoading());
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('❌ Google sign-in cancelled by user.');
        emit(Unauthenticated());
        print('🚫 Emitted Unauthenticated state.');
        return;
      }
      print('🔑 Google user signed in: ${googleUser.email}');

      final googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print(
          '⚠️ Failed to get Google authentication tokens (access or ID token is null).',
        );
        emit(AuthError('Failed to get Google authentication tokens'));
        print('🚨 Emitted AuthError state.');
        return;
      }
      print(
        '🆔 Google access token: ${googleAuth.accessToken?.substring(0, 10)}...',
      );
      print('🔥 Google ID token: ${googleAuth.idToken?.substring(0, 10)}...');

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      print('🔥 GoogleAuthProvider credential created.');

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      print(
        '🔥 Firebase sign-in with Google successful. User UID: ${userCredential.user?.uid}',
      );
      emit(Authenticated(userCredential.user!));
      print('✅ Emitted Authenticated state.');
      // Remove the manual navigation code
      // _navigationService.navigateTo('/home'); // ⚠️ Navigation should ideally be a side-effect in the UI layer
    } catch (e) {
      print('🚨 Error during Google sign-in: $e');
      emit(AuthError(e.toString()));
      print('🚨 Emitted AuthError state with message: $e');
    }
  }

  Future<void> _onSignInWithApplePressed(
    SignInWithApplePressed event,
    Emitter<AuthState> emit,
  ) async {
    print('🍎 SignInWithApplePressed event received.');
    try {
      print('⏳ Emitting AuthLoading state.');
      emit(AuthLoading());
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      print(
        '🍎 Apple ID credential obtained. User ID: ${appleCredential.userIdentifier}',
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      print('🍎 OAuthProvider credential for Apple created.');

      final userCredential = await _firebaseAuth.signInWithCredential(
        oauthCredential,
      );
      print(
        '🍎 Firebase sign-in with Apple successful. User UID: ${userCredential.user?.uid}',
      );
      emit(Authenticated(userCredential.user!));
      print('✅ Emitted Authenticated state.');
      // Remove the manual navigation code
      // _navigationService.navigateTo('/home'); // ⚠️ Navigation should ideally be a side-effect in the UI layer
    } catch (e) {
      print('🚨 Error during Apple sign-in: $e');
      emit(AuthError(e.toString()));
      print('🚨 Emitted AuthError state with message: $e');
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('👋 SignOutRequested event received.');
    try {
      print('⏳ Performing sign out...');
      await _firebaseAuth.signOut();
      print('🔥 Firebase sign out successful.');
      await _googleSignIn.signOut();
      print(
        '<0xF0><0x9F><0x93><0x81> Google sign out successful (if signed in).',
      );
      emit(Unauthenticated());
      print('🚫 Emitted Unauthenticated state.');
      // _navigationService.navigateTo('/login'); // ⚠️ Navigation should ideally be a side-effect in the UI layer
    } catch (e) {
      print('🚨 Error during sign out: $e');
      emit(AuthError(e.toString()));
      print('🚨 Emitted AuthError state with message: $e');
    }
  }
}
