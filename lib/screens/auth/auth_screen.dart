import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('🎨 AuthScreen widget built.');
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          print(
            '👂 AuthScreen - BlocConsumer listener triggered. State: $state',
          );
          if (state is AuthError) {
            print('❌ Auth Error detected in listener: ${state.message}');
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            print('💬 SnackBar shown with error message: ${state.message}');
          } else if (state is Authenticated) {
            print('✅ User authenticated! Navigating...');
            // 🚀 Ideally, navigation should happen in response to this state elsewhere
          } else if (state is Unauthenticated) {
            print('🚪 User is unauthenticated.');
          }
        },
        builder: (context, state) {
          print(
            '🧱 AuthScreen - BlocConsumer builder triggered. State: $state',
          );

          if (state is AuthLoading) {
            print('⏳ State is AuthLoading. Showing CircularProgressIndicator.');
            return const Center(child: CircularProgressIndicator());
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Event Manager',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton.icon(
                    onPressed: () {
                      print('🔘 Google Sign In Button Pressed');
                      context.read<AuthBloc>().add(SignInWithGooglePressed());
                      print(
                        '➡️ SignInWithGooglePressed event added to AuthBloc.',
                      );
                    },
                    icon: Image.network(
                      'https://www.gstatic.com/marketing-cms/assets/images/d5/dc/cfe9ce8b4425b410b49b7f2dd3f3/g.webp=s96-fcrop64=1,00000000ffffffff-rw',
                      height: 24,
                      errorBuilder: (context, error, stackTrace) {
                        print('⚠️ Error loading Google logo: $error');
                        return const Icon(Icons.error);
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          print('🖼️ Google logo loaded.');
                          return child;
                        }
                        print(
                          '⏳ Loading Google logo: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}',
                        );
                        return const SizedBox(
                          height: 24,
                          width: 24,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                    ),
                    label: const Text('Sign in with Google'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      print('🍎 Apple Sign In Button Pressed');
                      context.read<AuthBloc>().add(SignInWithApplePressed());
                      print(
                        '➡️ SignInWithApplePressed event added to AuthBloc.',
                      );
                    },
                    icon: const Icon(Icons.apple),
                    label: const Text('Sign in with Apple'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
