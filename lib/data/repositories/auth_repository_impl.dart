import 'dart:async';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  UserProfile? _currentUser;
  final StreamController<UserProfile?> _authController = StreamController<UserProfile?>.broadcast();

  AuthRepositoryImpl();

  @override
  Stream<UserProfile?> get authStateChanges => _authController.stream;

  @override
  Future<UserProfile> login(String email, String password) async {
    final user = UserProfile(
      uid: 'local_user_${email.hashCode}',
      email: email,
      name: email.contains('@') ? email.split('@').first : email,
      tickets: 5,
      coins: 100,
      unlockedChapters: const [],
      role: email.contains('admin') ? 'admin' : 'user',
    );
    _currentUser = user;
    _authController.add(_currentUser);
    return user;
  }

  @override
  Future<UserProfile> register(String email, String password, String name) async {
    final user = UserProfile(
      uid: 'local_user_${email.hashCode}',
      email: email,
      name: name.isNotEmpty ? name : 'User',
      tickets: 5,
      coins: 100,
      unlockedChapters: const [],
      role: 'user',
    );
    _currentUser = user;
    _authController.add(_currentUser);
    return user;
  }

  @override
  Future<UserProfile> signInWithGoogle() async {
    return login('google_user@gmail.com', 'pass');
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    _authController.add(null);
  }

  @override
  Future<UserProfile?> getCurrentUserProfile() async {
    return _currentUser;
  }

  @override
  Future<void> updateUserStats(int tickets, int coins, List<String> chapters) async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        tickets: tickets,
        coins: coins,
        unlockedChapters: chapters,
      );
      _authController.add(_currentUser);
    }
  }

  @override
  Future<List<UserProfile>> getAllUsersForLeaderboard() async {
    if (_currentUser != null) {
      return [_currentUser!];
    }
    return [];
  }

  @override
  Future<void> updateStoryPublishDate(String storyId, String lang, DateTime? publishDate) async {}

  @override
  Future<void> promoteUserToAdmin(String targetUid) async {}
}
