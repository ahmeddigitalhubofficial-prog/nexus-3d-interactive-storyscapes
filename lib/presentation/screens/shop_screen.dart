import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audioplayers/audioplayers.dart';
import '../cubit/save_cubit.dart';
import '../cubit/language_cubit.dart';
import '../cubit/auth/auth_cubit.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playPurchaseSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audio/coin_reward.mp3'));
    } catch (_) {}
  }

  String _t(String lang, String key) {
    return _localizations[lang]?[key] ?? key;
  }

  void _buyBundle(BuildContext context, int ticketCount, int coinCost, String lang) async {
    final saveCubit = context.read<SaveCubit>();
    final authCubit = context.read<AuthCubit>();
    
    final success = await saveCubit.buyTicketsWithCoins(ticketCount, coinCost);
    
    if (success) {
      _playPurchaseSound();
      
      // Update stats on AuthCubit as well to sync to Firestore immediately
      final updatedGlobal = saveCubit.state.globalState;
      await authCubit.syncUserStats(
        updatedGlobal.tickets,
        updatedGlobal.coins,
        updatedGlobal.unlockedChapters,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF69F0AE),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Color(0xFF0C091F)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _t(lang, 'purchase_success')
                      .replaceAll('{t}', ticketCount.toString())
                      .replaceAll('{c}', coinCost.toString()),
                  style: const TextStyle(color: Color(0xFF0C091F), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFFF1744),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _t(lang, 'insufficient_coins'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageCubit>().state;
    final saveState = context.watch<SaveCubit>().state;
    final globalState = saveState.globalState;

    return Scaffold(
      appBar: AppBar(
        title: Text(_t(lang, 'shop_title')),
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
          // Galactic background
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
          
          // Glowing nebulas
          Positioned(
            top: 100,
            right: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFC107).withValues(alpha: 0.12),
                    blurRadius: 100,
                    spreadRadius: 60,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -60,
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
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Balances Row
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                              ),
                              child: Column(
                                children: [
                                  const Text('🪙', style: TextStyle(fontSize: 28)),
                                  const SizedBox(height: 8),
                                  Text(
                                    globalState.coins.toString(),
                                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _t(lang, 'lbl_coins'),
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                              ),
                              child: Column(
                                children: [
                                  const Text('🎟️', style: TextStyle(fontSize: 28)),
                                  const SizedBox(height: 8),
                                  Text(
                                    globalState.tickets.toString(),
                                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _t(lang, 'lbl_tickets'),
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  Text(
                    _t(lang, 'store_headline'),
                    style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // 2. Bundles List
                  Expanded(
                    child: ListView(
                      children: [
                        _buildBundleCard(
                          context: context,
                          packName: _t(lang, 'pack1_name'),
                          tickets: 5,
                          cost: 50,
                          lang: lang,
                          color: const Color(0xFF80D8FF),
                        ),
                        _buildBundleCard(
                          context: context,
                          packName: _t(lang, 'pack2_name'),
                          tickets: 12,
                          cost: 100,
                          lang: lang,
                          color: const Color(0xFFE040FB),
                          isPopular: true,
                        ),
                        _buildBundleCard(
                          context: context,
                          packName: _t(lang, 'pack3_name'),
                          tickets: 30,
                          cost: 200,
                          lang: lang,
                          color: const Color(0xFFFFD700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBundleCard({
    required BuildContext context,
    required String packName,
    required int tickets,
    required int cost,
    required String lang,
    required Color color,
    bool isPopular = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPopular ? color.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.08),
          width: isPopular ? 1.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isPopular ? color.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.02),
            ),
            child: Row(
              children: [
                // Glowing Ticket icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: const Center(
                    child: Text('🎟️', style: TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 16),
                // Pack Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            packName,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          if (isPopular)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _t(lang, 'lbl_popular'),
                                style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+$tickets ${_t(lang, 'lbl_tickets')}',
                        style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                // Price / Buy button
                ElevatedButton(
                  onPressed: () => _buyBundle(context, tickets, cost, lang),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '🪙 $cost',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Localizations maps
const Map<String, Map<String, String>> _localizations = {
  'en': {
    'shop_title': 'Cosmic Store',
    'lbl_coins': 'Stardust Coins',
    'lbl_tickets': 'Tickets',
    'store_headline': 'TRADE YOUR COINS FOR TICKET PACKS',
    'lbl_popular': 'BEST VALUE',
    'pack1_name': 'Comet Bundle',
    'pack2_name': 'Supernova Pack',
    'pack3_name': 'Nebula Treasury',
    'purchase_success': 'Successfully traded for {t} tickets!',
    'insufficient_coins': 'Not enough Stardust Coins!',
  },
  'ar': {
    'shop_title': 'المتجر الكوني',
    'lbl_coins': 'عملات السديم',
    'lbl_tickets': 'التذاكر المتاحة',
    'store_headline': 'استبدل عملاتك الذهبية بباقات التذاكر',
    'lbl_popular': 'الأكثر شعبية',
    'pack1_name': 'باقة المذنب',
    'pack2_name': 'حزمة المستعر الأعظم',
    'pack3_name': 'خزنة السديم العظمى',
    'purchase_success': 'تم استبدال عملاتك بنجاح والحصول على {t} تذكرة!',
    'insufficient_coins': 'عذراً، ليس لديك عملات كافية!',
  }
};
