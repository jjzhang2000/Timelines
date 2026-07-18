import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [Locale('zh'), Locale('en')];

  static final Map<String, Map<String, String>> _localizedValues = {
    'zh': {
      'appTitle': '时间线',
      'search': '搜索',
      'filter': '筛选',
      'mergedView': '合并视图',
      'compareView': '对比视图',
      'selectAll': '全选',
      'deselectAll': '全不选',
      'detail': '详情',
      'loading': '加载中...',
      'error': '错误',
      'retry': '重试',
      'noData': '暂无数据',
    },
    'en': {
      'appTitle': 'Timelines',
      'search': 'Search',
      'filter': 'Filter',
      'mergedView': 'Merged View',
      'compareView': 'Compare View',
      'selectAll': 'Select All',
      'deselectAll': 'Deselect All',
      'detail': 'Detail',
      'loading': 'Loading...',
      'error': 'Error',
      'retry': 'Retry',
      'noData': 'No data available',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  String get appTitle => translate('appTitle');
  String get search => translate('search');
  String get filter => translate('filter');
  String get mergedView => translate('mergedView');
  String get compareView => translate('compareView');
  String get selectAll => translate('selectAll');
  String get deselectAll => translate('deselectAll');
  String get detail => translate('detail');
  String get loading => translate('loading');
  String get error => translate('error');
  String get retry => translate('retry');
  String get noData => translate('noData');

  String eventsCount(int count) {
    if (locale.languageCode == 'zh') {
      return '$count 个事件';
    }
    return '$count events';
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (l) => l.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
