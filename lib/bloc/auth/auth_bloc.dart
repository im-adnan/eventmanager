import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:eventmanager/services/navigation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class SignInWithGooglePressed extends AuthEvent {}

class SignInWithApplePressed extends AuthEvent {}

class SignOutRequested extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;

  Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthBloc()
    : _firebaseAuth = FirebaseAuth.instance,
      _googleSignIn = GoogleSignIn(),
      super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<SignInWithGooglePressed>(
      _onSignInWithGooglePressed
          as EventHandler<SignInWithGooglePressed, AuthState>,
    );
    on<SignInWithApplePressed>(_onSignInWithApplePressed);
    on<SignOutRequested>(_onSignOutRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      emit(Authenticated(user));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onSignInWithGooglePressed(
    SignInWithGooglePressed event,
    Emitter<AuthState> emit,
  ) async {
    final context = NavigationService.navigatorKey.currentContext!;
    try {
      emit(AuthLoading());
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        emit(Unauthenticated());
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      emit(Authenticated(userCredential.user!));
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignInWithApplePressed(
    SignInWithApplePressed event,
    Emitter<AuthState> emit,
  ) async {
    final context = NavigationService.navigatorKey.currentContext!;
    try {
      emit(AuthLoading());
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        oauthCredential,
      );
      emit(Authenticated(userCredential.user!));
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
