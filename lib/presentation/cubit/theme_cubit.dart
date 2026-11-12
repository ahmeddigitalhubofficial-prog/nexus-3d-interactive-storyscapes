import 'package:flutter_bloc/flutter_bloc.dart';

class ThemeCubit extends Cubit<String> {
  ThemeCubit() : super('menu');

  void setMenuTheme() => emit('menu');
  
  void setStoryTheme(String storyId) {
    if (storyId.contains('horror')) {
      emit('horror');
    } else if (storyId.contains('comedy')) {
      emit('comedy');
    } else if (storyId.contains('history')) {
      emit('historical');
    } else {
      emit('menu');
    }
  }
}
