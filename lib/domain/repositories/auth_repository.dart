import '../entities/user_profile.dart';

abstract class AuthRepository {
  Future<UserProfile> login(String email, String password);
  Future<UserProfile> register(String email, String password, String name);
  Future<UserProfile> signInWithGoogle();
  Future<void> logout();
  Future<UserProfile?> getCurrentUserProfile();
  Stream<UserProfile?> get authStateChanges;
  Future<void> updateUserStats(int tickets, int coins, List<String> chapters);
  Future<List<UserProfile>> getAllUsersForLeaderboard();
  Future<void> updateStoryPublishDate(String storyId, String lang, DateTime? publishDate);
  Future<void> promoteUserToAdmin(String targetUid);
}
