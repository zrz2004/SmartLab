import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/local_storage_service.dart';

class LocaleCubit extends Cubit<Locale> {
  LocaleCubit({required LocalStorageService storageService})
      : _storageService = storageService,
        super(const Locale('zh'));

  final LocalStorageService _storageService;

  static const _supportedLanguageCodes = <String>{'zh', 'en'};

  void loadSavedLocale() {
    final code = _storageService.getLanguageCode();
    if (_supportedLanguageCodes.contains(code)) {
      emit(Locale(code));
    }
  }

  Future<void> setLanguage(String languageCode) async {
    if (!_supportedLanguageCodes.contains(languageCode) || state.languageCode == languageCode) {
      return;
    }
    await _storageService.setLanguageCode(languageCode);
    emit(Locale(languageCode));
  }
}
