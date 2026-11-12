import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/localization/app_localizations.dart';
import '../cubit/language_cubit.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageCubit>().state;
    final l10n = AppLocalizations(lang);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('admin_dashboard')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00E5FF),
          labelColor: const Color(0xFF00E5FF),
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: lang == 'ar' ? 'قصص إنجليزية' : 'EN Stories'),
            Tab(text: lang == 'ar' ? 'قصص عربية' : 'AR Stories'),
            Tab(text: l10n.translate('all_users')),
          ],
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
                    Color(0xFF0F0B26),
                    Color(0xFF0A091A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Glow Background Highlights
          Positioned(
            top: 150,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.12),
                    blurRadius: 100,
                    spreadRadius: 60,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 150,
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
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStoriesTab(context, 'en', l10n),
                _buildStoriesTab(context, 'ar', l10n),
                _buildUsersTab(context, l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesTab(BuildContext context, String storyLang, AppLocalizations l10n) {
    return const Center(
      child: Text(
        'Offline Mode — Local Stories Active',
        style: TextStyle(color: Colors.white60),
      ),
    );
  }

  Widget _buildUsersTab(BuildContext context, AppLocalizations l10n) {
    return const Center(
      child: Text(
        'Offline Mode — Local Users Active',
        style: TextStyle(color: Colors.white60),
      ),
    );
  }
}
