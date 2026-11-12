import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_profile.dart';
import '../cubit/language_cubit.dart';
import '../cubit/auth/auth_cubit.dart';

class LeaderboardsScreen extends StatefulWidget {
  const LeaderboardsScreen({super.key});

  @override
  State<LeaderboardsScreen> createState() => _LeaderboardsScreenState();
}

class _LeaderboardsScreenState extends State<LeaderboardsScreen> {
  List<UserProfile> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await context.read<AuthCubit>().authRepository.getAllUsersForLeaderboard();
      setState(() {
        _users = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _t(String lang, String key) {
    return _localizations[lang]?[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageCubit>().state;

    return Scaffold(
      appBar: AppBar(
        title: Text(_t(lang, 'leaderboard_title')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF03001e),
                    Color(0xFF130F30),
                    Color(0xFF0D0B1A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          
          // Glowing Ambient Blobs
          Positioned(
            top: 200,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                    blurRadius: 100,
                    spreadRadius: 60,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: $_error', style: const TextStyle(color: Colors.redAccent)),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: _loadLeaderboard, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _users.isEmpty
                        ? Center(child: Text(_t(lang, 'empty_leaderboard'), style: const TextStyle(color: Colors.white54)))
                        : Column(
                            children: [
                              // 1. Podiums for Top 3 (if we have at least 1 user)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16),
                                child: _buildPodiumSection(lang),
                              ),
                              
                              // 2. Remaining users list
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(30),
                                    topRight: Radius.circular(30),
                                  ),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.03),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(30),
                                          topRight: Radius.circular(30),
                                        ),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                                      ),
                                      child: ListView.builder(
                                        padding: const EdgeInsets.all(20),
                                        itemCount: _users.length > 3 ? _users.length - 3 : 0,
                                        itemBuilder: (context, index) {
                                          final user = _users[index + 3];
                                          final rank = index + 4;
                                          return _buildLeaderboardRow(user, rank, lang);
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumSection(String lang) {
    // Determine 1st, 2nd, 3rd
    final UserProfile? first = _users.isNotEmpty ? _users[0] : null;
    final UserProfile? second = _users.length > 1 ? _users[1] : null;
    final UserProfile? third = _users.length > 2 ? _users[2] : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd Place (Silver)
        if (second != null)
          _buildPodiumUser(second, 2, const Color(0xFFC0C0C0), 100, lang),
        
        // 1st Place (Gold)
        if (first != null)
          _buildPodiumUser(first, 1, const Color(0xFFFFD700), 125, lang),
        
        // 3rd Place (Bronze)
        if (third != null)
          _buildPodiumUser(third, 3, const Color(0xFFCD7F32), 90, lang),
      ],
    );
  }

  Widget _buildPodiumUser(UserProfile user, int rank, Color rankColor, double avatarSize, String lang) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [rankColor.withValues(alpha: 0.8), rankColor.withValues(alpha: 0.3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: rankColor.withValues(alpha: 0.2),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF0F0C20),
                  ),
                  child: Center(
                    child: Text(
                      user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : '?',
                      style: TextStyle(
                        color: rankColor,
                        fontSize: avatarSize * 0.35,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: rankColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: rankColor.withValues(alpha: 0.3),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                    color: Color(0xFF0C091F),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          user.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          '${user.unlockedChapters.length} ${_t(lang, 'stat_stories')}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardRow(UserProfile user, int rank, String lang) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          // Rank ID
          Text(
            '#$rank',
            style: const TextStyle(
              color: Color(0xFF00E5FF),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 16),
          // User Avatar Initial
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            child: Text(
              user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : '?',
              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          // User details
          Expanded(
            child: Text(
              user.name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          // Count of Chapters
          Text(
            '${user.unlockedChapters.length} ${_t(lang, 'stat_stories')}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// Localizations dictionary
const Map<String, Map<String, String>> _localizations = {
  'en': {
    'leaderboard_title': 'Galactic Standings',
    'empty_leaderboard': 'No users on the leaderboard yet.',
    'stat_stories': 'stories',
  },
  'ar': {
    'leaderboard_title': 'ترتيب المجرة',
    'empty_leaderboard': 'لا يوجد مستخدمون في لوحة المتصدرين بعد.',
    'stat_stories': 'قصص مفتوحة',
  }
};
