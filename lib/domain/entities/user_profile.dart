import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String role; // 'admin' or 'user'
  final int tickets;
  final int coins;
  final List<String> unlockedChapters;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.role = 'user',
    this.tickets = 10,
    this.coins = 100,
    this.unlockedChapters = const [],
  });

  UserProfile copyWith({
    String? uid,
    String? name,
    String? email,
    String? role,
    int? tickets,
    int? coins,
    List<String>? unlockedChapters,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      tickets: tickets ?? this.tickets,
      coins: coins ?? this.coins,
      unlockedChapters: unlockedChapters ?? this.unlockedChapters,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json, String uid) {
    return UserProfile(
      uid: uid,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      tickets: json['tickets'] as int? ?? 10,
      coins: json['coins'] as int? ?? 100,
      unlockedChapters: (json['unlocked_chapters'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'tickets': tickets,
      'coins': coins,
      'unlocked_chapters': unlockedChapters,
    };
  }

  bool get isAdmin => role == 'admin';

  @override
  List<Object?> get props => [uid, name, email, role, tickets, coins, unlockedChapters];
}
