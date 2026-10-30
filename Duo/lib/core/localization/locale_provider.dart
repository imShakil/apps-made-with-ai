import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocaleNotifier extends StateNotifier<String> {
  LocaleNotifier() : super('en'); // 'en' or 'bn'

  void setLocale(String lang) {
    if (state != lang) {
      state = lang;
    }
  }

  void toggleLocale() {
    state = state == 'en' ? 'bn' : 'en';
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, String>((ref) {
  return LocaleNotifier();
});
