import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;
  StreamSubscription? _authSubscription;

  AuthCubit({required this.authRepository}) : super(AuthInitial()) {
    // Listen to authentication changes automatically
    _authSubscription = authRepository.authStateChanges.listen((userProfile) {
      if (userProfile != null) {
        emit(AuthAuthenticated(userProfile));
      } else {
        emit(AuthUnauthenticated());
      }
    });
  }

  Future<void> checkAuthStatus() async {
    emit(AuthInitialChecking());
    try {
      final profile = await authRepository.getCurrentUserProfile();
      if (profile != null) {
        emit(AuthAuthenticated(profile));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      await authRepository.login(email, password);
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> register(String email, String password, String name) async {
    emit(AuthLoading());
    try {
      await authRepository.register(email, password, name);
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> loginWithGoogle() async {
    emit(AuthLoading());
    try {
      await authRepository.signInWithGoogle();
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());
    try {
      await authRepository.logout();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> syncUserStats(int tickets, int coins, List<String> chapters) async {
    if (state is AuthAuthenticated) {
      final currentProfile = (state as AuthAuthenticated).userProfile;
      final updatedProfile = currentProfile.copyWith(
        tickets: tickets,
        coins: coins,
        unlockedChapters: chapters,
      );
      emit(AuthAuthenticated(updatedProfile));
      await authRepository.updateUserStats(tickets, coins, chapters);
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
