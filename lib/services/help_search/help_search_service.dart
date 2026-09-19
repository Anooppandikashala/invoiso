import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:fuzzywuzzy/fuzzywuzzy.dart' show extractAllSorted;
import 'package:invoiso/services/faq_service.dart';
import 'package:invoiso/services/help_search/searchable_item.dart';

class _Candidate {
  final SearchableItem item;
  final String text;

  const _Candidate(this.item, this.text);
}

class HelpSearchService {
  static const _settingsAssetPath = 'assets/data/settings.json';

  static List<SearchableItem>? _cachedIndex;

  /// Builds (or returns the cached) unified FAQ + Settings search index.
  /// Pass [forceRefresh] to re-fetch the FAQ source and rebuild.
  static Future<List<SearchableItem>> buildIndex({bool forceRefresh = false}) async {
    if (_cachedIndex != null && !forceRefresh) return _cachedIndex!;

    final items = <SearchableItem>[];

    final faqData = await FaqService.load(force: forceRefresh);
    final categoryLabels = <String, String>{
      for (final c in (faqData['categories'] as List? ?? []))
        (c as Map)['id'] as String: c['label'] as String,
    };
    for (final raw in (faqData['items'] as List? ?? [])) {
      final map = raw as Map;
      final categoryId = map['category'] as String?;
      items.add(SearchableItem(
        id: map['id'] as String,
        type: SearchableItemType.faq,
        question: map['question'] as String,
        answer: map['answer'] as String,
        keywords: List<String>.from(map['keywords'] as List? ?? const []),
        path: ['FAQ', if (categoryId != null) categoryLabels[categoryId] ?? categoryId],
      ));
    }

    final settingsRaw = await rootBundle.loadString(_settingsAssetPath);
    final settingsData = jsonDecode(settingsRaw) as Map<String, dynamic>;
    final screenLabels = <String, String>{
      for (final s in (settingsData['screens'] as List? ?? []))
        (s as Map)['key'] as String: s['label'] as String,
    };
    final screenGroups = <String, String>{
      for (final s in (settingsData['screens'] as List? ?? []))
        (s as Map)['key'] as String: (s['group'] as String?) ?? 'Settings',
    };
    for (final raw in (settingsData['items'] as List? ?? [])) {
      final map = raw as Map;
      final screenKey = map['screen'] as String?;
      final section = map['section'] as String?;
      final screenLabel = screenKey != null ? (screenLabels[screenKey] ?? screenKey) : null;
      final group = screenKey != null ? (screenGroups[screenKey] ?? 'Settings') : 'Settings';
      items.add(SearchableItem(
        id: map['id'] as String,
        type: SearchableItemType.setting,
        question: map['question'] as String,
        answer: map['description'] as String,
        keywords: List<String>.from(map['keywords'] as List? ?? const []),
        path: [
          group,
          if (screenLabel != null && screenLabel != group) screenLabel,
          if (section != null && section != screenLabel) section,
        ],
      ));
    }

    _cachedIndex = items;
    return items;
  }

  /// Searches the given [index] for [query] using fuzzy (Levenshtein-based)
  /// matching, ranked by score descending. Only results scoring above
  /// [cutoff] (0-100) are returned.
  ///
  /// Each item is scored as multiple short candidates (its question, and
  /// each keyword individually) rather than one long concatenated string —
  /// WeightedRatio penalizes large length mismatches between the query and
  /// the text it's compared against, so a single blob of 5-10 keywords
  /// tacked onto a question drags every score down regardless of match
  /// quality. The item's best-scoring candidate wins.
  static List<ScoredSearchResult> search(
    List<SearchableItem> index,
    String query, {
    int cutoff = 65,
    int limit = 20,
  }) {
    if (query.trim().isEmpty) return const [];

    final candidates = <_Candidate>[];
    for (final item in index) {
      candidates.add(_Candidate(item, item.question));
      for (final keyword in item.keywords) {
        candidates.add(_Candidate(item, keyword));
      }
    }

    final results = extractAllSorted(
      query: query,
      choices: candidates,
      cutoff: cutoff,
      getter: (c) => c.text,
    );

    final bestByItemId = <String, ScoredSearchResult>{};
    for (final r in results) {
      final id = r.choice.item.id;
      final existing = bestByItemId[id];
      if (existing == null || existing.score < r.score) {
        bestByItemId[id] = ScoredSearchResult(r.choice.item, r.score);
      }
    }

    final sorted = bestByItemId.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return sorted.take(limit).toList();
  }
}
