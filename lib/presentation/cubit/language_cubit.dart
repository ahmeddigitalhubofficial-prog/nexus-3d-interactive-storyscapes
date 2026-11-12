import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageCubit extends Cubit<String> {
  static const String _langKey = 'user_language';
  final SharedPreferences prefs;

  LanguageCubit({required this.prefs}) : super(prefs.getString(_langKey) ?? 'ar');

  Future<void> changeLanguage(String langCode) async {
    if (langCode == 'ar' || langCode == 'en') {
      await prefs.setString(_langKey, langCode);
      emit(langCode);
    }
  }
}
