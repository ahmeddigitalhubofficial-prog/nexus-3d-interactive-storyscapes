import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth/auth_cubit.dart';
import '../cubit/auth/auth_state.dart';
import '../cubit/save_cubit.dart';
import '../cubit/language_cubit.dart';
import '../widgets/auth_gate.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _t(String lang, String key) {
    return _localizations[lang]?[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageCubit>().state;
    final saveState = context.watch<SaveCubit>().state;
    final globalState = saveState.globalState;
    
    // Calculate stats
    final endingsCount = globalState.unlockedEndings.values.fold(0, (sum, list) => sum + list.length);
    final achievementsCount = globalState.unlockedAchievements.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_t(lang, 'profile')),
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
                    Color(0xFF150A21),
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
            top: 100,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD500F9).withValues(alpha: 0.15),
                    blurRadius: 100,
                    spreadRadius: 60,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                    blurRadius: 100,
                    spreadRadius: 60,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                if (state is! AuthAuthenticated) {
                  return const Center(child: CircularProgressIndicator());
                }

                final profile = state.userProfile;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Profile header with avatar
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF00E5FF), Color(0xFFD500F9)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF0F0C20),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.face_retouching_natural,
                                      size: 56,
                                      color: Color(0xFF00E5FF),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              profile.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              profile.email,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Role Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: profile.isAdmin
                                    ? const Color(0xFFFFD700).withValues(alpha: 0.12)
                                    : Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: profile.isAdmin
                                      ? const Color(0xFFFFD700).withValues(alpha: 0.4)
                                      : Colors.white.withValues(alpha: 0.12),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    profile.isAdmin ? Icons.workspace_premium : Icons.person,
                                    size: 14,
                                    color: profile.isAdmin ? const Color(0xFFFFD700) : Colors.white70,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    profile.isAdmin
                                        ? _t(lang, 'role_admin')
                                        : _t(lang, 'role_user'),
                                    style: TextStyle(
                                      color: profile.isAdmin ? const Color(0xFFFFD700) : Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),

                      // 2. Stats Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.4,
                        children: [
                          _buildStatCard(
                            context,
                            '🎟️',
                            globalState.tickets.toString(),
                            _t(lang, 'stat_tickets'),
                            const Color(0xFF00E5FF),
                          ),
                          _buildStatCard(
                            context,
                            '🪙',
                            globalState.coins.toString(),
                            _t(lang, 'stat_coins'),
                            const Color(0xFFFFC107),
                          ),
                          _buildStatCard(
                            context,
                            '🎬',
                            endingsCount.toString(),
                            _t(lang, 'stat_endings'),
                            const Color(0xFFE040FB),
                          ),
                          _buildStatCard(
                            context,
                            '🏆',
                            achievementsCount.toString(),
                            _t(lang, 'stat_achievements'),
                            const Color(0xFF69F0AE),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // 3. User info details card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  _t(lang, 'account_info'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildDetailRow(
                                  context,
                                  _t(lang, 'label_uid'),
                                  profile.uid,
                                  Icons.fingerprint,
                                ),
                                const Divider(color: Colors.white10),
                                _buildDetailRow(
                                  context,
                                  _t(lang, 'label_unlocked'),
                                  '${globalState.unlockedChapters.length} ${_t(lang, 'stories')}',
                                  Icons.book,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // 4. Logout Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent, width: 1.5),
                          shadowColor: Colors.redAccent.withValues(alpha: 0.3),
                          elevation: 8,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.logout),
                        label: Text(
                          _t(lang, 'logout'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          context.read<AuthCubit>().logout();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const AuthGate()),
                            (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String icon,
    String count,
    String label,
    Color glowColor,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: glowColor,
                      boxShadow: [
                        BoxShadow(
                          color: glowColor,
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF00E5FF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// English & Arabic Localization Dictionary
const Map<String, Map<String, String>> _localizations = {
  'en': {
    'profile': 'Cosmic Profile',
    'role_admin': 'Admin Mode',
    'role_user': 'Space Traveler',
    'stat_tickets': 'Tickets',
    'stat_coins': 'Stardust Coins',
    'stat_endings': 'Endings Discovered',
    'stat_achievements': 'Achievements',
    'account_info': 'Account Metadata',
    'label_uid': 'User Identifier (UID)',
    'label_unlocked': 'Library Access',
    'stories': 'stories',
    'logout': 'Log Out',
  },
  'ar': {
    'profile': 'الملف الشخصي الكوني',
    'role_admin': 'الـمـشـرف',
    'role_user': 'مسافر الفضاء',
    'stat_tickets': 'التذاكر المتاحة',
    'stat_coins': 'عملات السديم',
    'stat_endings': 'النهايات المكتشفة',
    'stat_achievements': 'الإنجازات المفتوحة',
    'account_info': 'بيانات الحساب الأساسية',
    'label_uid': 'المعرف الفريد للمستند (UID)',
    'label_unlocked': 'الولوج للمكتبة',
    'stories': 'قصص مفتوحة',
    'logout': 'تسجيل الخروج',
  }
};
