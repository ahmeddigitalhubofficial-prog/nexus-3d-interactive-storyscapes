import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/ads/ad_service.dart';
import '../cubit/language_cubit.dart';
import '../cubit/save_cubit.dart';
import '../cubit/theme_cubit.dart';
import '../cubit/auth/auth_cubit.dart';
import '../cubit/auth/auth_state.dart';
import '../widgets/glass_container.dart';
import 'library_screen.dart';
import 'achievements_screen.dart';
import 'profile_screen.dart';
import 'leaderboards_screen.dart';
import 'shop_screen.dart';
import 'admin_dashboard_screen.dart';
import 'three_d_game_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
    
    // Reset theme back to menu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ThemeCubit>().setMenuTheme();
      context.read<SaveCubit>().loadGlobalAndSlots();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // --- Show Save Slots Sheet ---
  void _showSaveSlots(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BlocBuilder<SaveCubit, SaveState>(
          builder: (context, state) {
            return GlassContainer(
              borderRadius: 24,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.translate('save_slots'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  ...state.slots.map((slot) {
                    final isUsed = slot.storyId != null;
                    return Card(
                      color: isUsed ? const Color(0xFF162235) : Colors.black26,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isUsed ? const Color(0xFF00E5FF).withValues(alpha: 0.5) : Colors.white10,
                        ),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          isUsed
                              ? l10n.translate('story_${slot.storyId}')
                              : '${l10n.translate('empty_slot')} ${slot.id}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: isUsed
                            ? Text(
                                'Last played: ${slot.lastPlayed.toLocal().toString().substring(0, 16)}',
                                style: const TextStyle(color: Colors.white60, fontSize: 12),
                              )
                            : null,
                        trailing: isUsed
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.play_circle_fill, color: Color(0xFF00E5FF), size: 32),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      // Load save logic (triggers on library screen)
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => LibraryScreen(resumeFromSlot: slot),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: () {
                                      context.read<SaveCubit>().deleteSlot(slot.id);
                                    },
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- Show Ad Watching Dialog ---
  void _showAdSimulation(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return BlocListener<SaveCubit, SaveState>(
          listenWhen: (previous, current) => previous.isWatchingAd && !current.isWatchingAd,
          listener: (context, state) {
            if (Navigator.canPop(dialogCtx)) {
              Navigator.pop(dialogCtx);
            }
          },
          child: BlocBuilder<SaveCubit, SaveState>(
            builder: (context, state) {
              return PopScope(
                canPop: false, // Prevent back button dismiss
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  child: GlassContainer(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.ondemand_video, color: Color(0xFF00E5FF), size: 64),
                        const SizedBox(height: 24),
                        Text(
                          l10n.translate('watch_ad_title'),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.translate('watch_ad_desc'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.translate('ad_countdown', replace: '{n}', withVal: state.adCountdown.toString()),
                          style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: (3 - state.adCountdown) / 3,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageCubit>().state;
    final l10n = AppLocalizations(language);
    final globalState = context.watch<SaveCubit>().state.globalState;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Beautiful Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF070B19), Color(0xFF0B1220), Color(0xFF16253D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          // 2. Animated Particle Fallback / Ambient decoration
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
                    blurRadius: 80,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.08),
                    blurRadius: 80,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          // 3. Menu Contents
          FadeTransition(
            opacity: _fadeAnimation,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header: Ticket count, Cosmo Coins, & Language Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // Tickets Indicator
                            GlassContainer(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              borderRadius: 20,
                              opacity: 0.1,
                              child: Row(
                                children: [
                                  const Text('🎟️', style: TextStyle(fontSize: 16)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${globalState.tickets}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Coins Indicator (Tapping navigates to Shop)
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ShopScreen()),
                                );
                              },
                              child: GlassContainer(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                borderRadius: 20,
                                opacity: 0.1,
                                child: Row(
                                  children: [
                                    const Text('🪙', style: TextStyle(fontSize: 16)),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${globalState.coins}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Language Dropdown Selector
                        GlassContainer(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          borderRadius: 20,
                          opacity: 0.1,
                          child: DropdownButton<String>(
                            value: language,
                            dropdownColor: const Color(0xFF162235),
                            underline: const SizedBox.shrink(),
                            icon: const Icon(Icons.language, color: Color(0xFF00E5FF)),
                            items: const [
                              DropdownMenuItem(value: 'ar', child: Text('العربية  ')),
                              DropdownMenuItem(value: 'en', child: Text('English  ')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                context.read<LanguageCubit>().changeLanguage(val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // App Title & Subtitle
                    Text(
                      l10n.translate('app_title'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF00E5FF),
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: Color(0xFF00E5FF),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Illustrated - Voiced - Augmented Reality',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white54,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(flex: 2),

                    // Menu Action Buttons
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE63946),
                        foregroundColor: Colors.white,
                        shadowColor: const Color(0xFFE63946).withValues(alpha: 0.6),
                        elevation: 10,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: const Icon(Icons.view_in_ar, size: 28),
                      label: const Text(
                        '🎮 PLAY 3D EXPERIENCE',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ThreeDGameScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LibraryScreen(),
                          ),
                        );
                      },
                      child: Text(
                        l10n.translate('library'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF7C4DFF), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _showSaveSlots(context, l10n),
                      child: Text(
                        l10n.translate('save_slots'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AchievementsScreen(),
                          ),
                        );
                      },
                      child: Text(
                        l10n.translate('achievements'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Earn Ticket with Ad Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50), // Green for reward
                        foregroundColor: Colors.white,
                        shadowColor: Colors.green.withValues(alpha: 0.5),
                        elevation: 8,
                      ),
                      icon: const Icon(Icons.ondemand_video),
                      label: Text(
                        l10n.translate('free_ticket'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        _showAdSimulation(context, l10n);
                        context.read<SaveCubit>().earnTicketWithAd(MockAdServiceImpl());
                      },
                    ),
                    const SizedBox(height: 16),

                    // Secondary screens navigation row
                    Row(
                      children: [
                        Expanded(
                          child: _buildSecondaryMenuButton(
                            context: context,
                            icon: Icons.person,
                            label: l10n.translate('profile'),
                            color: const Color(0xFF80D8FF),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ProfileScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSecondaryMenuButton(
                            context: context,
                            icon: Icons.emoji_events,
                            label: l10n.translate('leaderboard'),
                            color: const Color(0xFFFFD700),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LeaderboardsScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSecondaryMenuButton(
                            context: context,
                            icon: Icons.store,
                            label: l10n.translate('cosmic_shop'),
                            color: const Color(0xFFE040FB),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ShopScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    // Admin Dashboard Button (visible only if user role == 'admin')
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, authState) {
                        if (authState is AuthAuthenticated && authState.userProfile.isAdmin) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE040FB).withValues(alpha: 0.2),
                                foregroundColor: const Color(0xFFE040FB),
                                side: const BorderSide(color: Color(0xFFE040FB), width: 1.5),
                                shadowColor: const Color(0xFFE040FB).withValues(alpha: 0.5),
                                elevation: 8,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.admin_panel_settings, color: Color(0xFFE040FB)),
                              label: Text(
                                l10n.translate('admin_dashboard'),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                                );
                              },
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryMenuButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        borderRadius: 12,
        opacity: 0.05,
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
