import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../home/home_screen.dart';
import 'auth_screen.dart';

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    print('📦 AuthenticationWrapper widget built.');
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        print(
          '🌀 AuthenticationWrapper - BlocBuilder triggered. State: $state',
        );

        if (state is AuthLoading) {
          print('⏳ State is AuthLoading. Showing loading indicator.');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is Authenticated) {
          print('✅ State is Authenticated. User UID: ${state.user.uid}');
          print('➡️ Scheduling navigation to HomeScreen after current frame.');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            print('🚀 Performing navigation to HomeScreen.');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
            print('🏠 HomeScreen pushed.');
          });
          print(
            '👻 Returning SizedBox.shrink() to avoid UI flicker during navigation.',
          );
          return const SizedBox.shrink();
        }

        print(
          '🚪 State is not AuthLoading or Authenticated (likely Unauthenticated or AuthInitial). Showing AuthScreen.',
        );
        return const AuthScreen();
      },
    );
  }
}
