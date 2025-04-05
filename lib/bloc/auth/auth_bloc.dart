import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  AuthBloc() : _firebaseAuth = FirebaseAuth.instance, super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<SignInWithGooglePressed>(_onSignInWithGooglePressed);
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
    try {
      emit(AuthLoading());
      // Implement OAuth flow manually for Google
      // Obtain tokens and use FirebaseAuth to sign in
      // Example: final credential = GoogleAuthProvider.credential(...);
      // final userCredential = await _firebaseAuth.signInWithCredential(credential);
      // emit(Authenticated(userCredential.user!));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignInWithApplePressed(
    SignInWithApplePressed event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());
      // Implement OAuth flow manually for Apple
      // Obtain tokens and use FirebaseAuth to sign in
      // Example: final oauthCredential = OAuthProvider('apple.com').credential(...);
      // final userCredential = await _firebaseAuth.signInWithCredential(oauthCredential);
      // emit(Authenticated(userCredential.user!));
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
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
