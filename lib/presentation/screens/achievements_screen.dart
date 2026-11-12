import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/localization/app_localizations.dart';
import '../../domain/entities/game_state_models.dart';
import '../cubit/language_cubit.dart';
import '../cubit/save_cubit.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  // Simple static list of achievements supported in the system
  static const List<Achievement> allAchievements = [
    Achievement(
      id: 'ach_undamaged',
      titleAr: 'الناجي السليم',
      titleEn: 'Flawless Survivor',
      descriptionAr: 'أنهيت قصة الرعب بكامل صحتك',
      descriptionEn: 'Finished the horror story with full health',
    ),
    Achievement(
      id: 'ach_collector',
      titleAr: 'جامع الأدلة',
      titleEn: 'Clue Collector',
      descriptionAr: 'فتحت كتاب الأدلة وعثرت على أسرار خفية',
      descriptionEn: 'Unlocked a hidden diary or relic note',
    ),
    Achievement(
      id: 'ach_calm',
      titleAr: 'أعصاب حديدية',
      titleEn: 'Nerves of Steel',
      descriptionAr: 'اجتزت فحص نبضات القلب بنبض منخفض',
      descriptionEn: 'Passed the heart rate check with low heart rate',
    ),
    Achievement(
      id: 'ach_all_endings',
      titleAr: 'مستكشف الأقدار',
      titleEn: 'Fate Explorer',
      descriptionAr: 'فتحت جميع نهايات قصة واحدة',
      descriptionEn: 'Unlocked all endings of any story',
    ),
  ];

  static Achievement? getById(String id) {
    try {
      return allAchievements.firstWhere((ach) => ach.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageCubit>().state;
    final l10n = AppLocalizations(language);
    final globalState = context.watch<SaveCubit>().state.globalState;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('achievements')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Dark space background
          Container(
            color: const Color(0xFF0B1220),
          ),

          // ListView of achievements cards
          ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: allAchievements.length,
            itemBuilder: (context, index) {
              final ach = allAchievements[index];
              final isUnlocked = globalState.unlockedAchievements.contains(ach.id);
              final isAr = language == 'ar';

              final title = isAr ? ach.titleAr : ach.titleEn;
              final desc = isAr ? ach.descriptionAr : ach.descriptionEn;

              return Card(
                color: isUnlocked ? const Color(0xFF162235) : Colors.black45,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isUnlocked ? const Color(0xFF00E5FF).withValues(alpha: 0.5) : Colors.white10,
                  ),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: isUnlocked ? const Color(0xFF00E5FF).withValues(alpha: 0.2) : Colors.white10,
                    radius: 28,
                    child: Icon(
                      isUnlocked ? Icons.emoji_events : Icons.lock,
                      color: isUnlocked ? const Color(0xFF00E5FF) : Colors.white24,
                      size: 28,
                    ),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isUnlocked ? Colors.white : Colors.white30,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      desc,
                      style: TextStyle(
                        fontSize: 13,
                        color: isUnlocked ? Colors.white60 : Colors.white10,
                      ),
                    ),
                  ),
                  trailing: isUnlocked
                      ? const Icon(Icons.check_circle, color: Colors.green, size: 28)
                      : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
