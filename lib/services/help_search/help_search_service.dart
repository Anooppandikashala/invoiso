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

  /// Score credited to an item that matches every query word but wasn't
  /// found by the fuzzy pass at all — just needs to be above [search]'s
  /// default cutoff so it isn't dropped; its rank is decided by the
  /// all-tokens-matched tiering in [search], not this number.
  static const _multiWordMatchScore = 80;

  static List<String> _tokenize(String text) => text
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((t) => t.isNotEmpty)
      .toList();

  /// Searches the given [index] for [query], ranked by score descending.
  /// Only results scoring above [cutoff] (0-100) are returned.
  ///
  /// Combines two signals:
  /// 1. Fuzzy (Levenshtein-based) matching — good for typos and near
  ///    matches on a single phrase. Each item is scored as multiple short
  ///    candidates (its question, and each keyword individually) rather
  ///    than one long concatenated string — WeightedRatio penalizes large
  ///    length mismatches between the query and the text it's compared
  ///    against, so a single blob of 5-10 keywords tacked onto a question
  ///    drags every score down regardless of match quality. The item's
  ///    best-scoring candidate wins.
  /// 2. Multi-word, order-independent token coverage — the same style
  ///    Android's Contacts search uses: split the query into words and
  ///    check whether every one appears (as a substring) somewhere in the
  ///    item's question/keywords, in any order.
  ///
  /// For multi-word queries, (2) is the *primary* sort key, not just a
  /// fallback for items the fuzzy pass missed: an item containing every
  /// searched word must outrank one that only fuzzily resembles part of
  /// the query, even when the raw fuzzy ratio number says otherwise (e.g.
  /// "multi user" vs "How do I make a **user** an admin?" can out-score
  /// "How do I delete **multi**ple **user**s at once?" on pure ratio, even
  /// though only the second one actually contains both words). Fuzzy score
  /// is still used as the tiebreaker within each tier, and single-word
  /// queries are untouched (no tiering — pure fuzzy order, same as before).
  static List<ScoredSearchResult> search(
    List<SearchableItem> index,
    String query, {
    int cutoff = 65,
    int limit = 20,
  }) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return const [];

    final itemsById = {for (final item in index) item.id: item};

    final candidates = <_Candidate>[];
    for (final item in index) {
      candidates.add(_Candidate(item, item.question));
      for (final keyword in item.keywords) {
        candidates.add(_Candidate(item, keyword));
      }
    }

    final fuzzyResults = extractAllSorted(
      query: trimmedQuery,
      choices: candidates,
      cutoff: cutoff,
      getter: (c) => c.text,
    );

    final fuzzyScoreByItemId = <String, int>{};
    for (final r in fuzzyResults) {
      final id = r.choice.item.id;
      final existing = fuzzyScoreByItemId[id];
      if (existing == null || existing < r.score) {
        fuzzyScoreByItemId[id] = r.score;
      }
    }

    final queryTokens = _tokenize(trimmedQuery);
    final matchesAllTokens = <String, bool>{};
    if (queryTokens.length > 1) {
      for (final item in index) {
        final haystack = _tokenize([item.question, ...item.keywords].join(' '));
        matchesAllTokens[item.id] =
            queryTokens.every((qt) => haystack.any((ht) => ht.contains(qt)));
      }
    }

    final resultIds = <String>{
      ...fuzzyScoreByItemId.keys,
      ...matchesAllTokens.entries.where((e) => e.value).map((e) => e.key),
    };

    final results = [
      for (final id in resultIds)
        ScoredSearchResult(
          itemsById[id]!,
          fuzzyScoreByItemId[id] ?? _multiWordMatchScore,
        ),
    ];

    results.sort((a, b) {
      final aAll = matchesAllTokens[a.item.id] ?? false;
      final bAll = matchesAllTokens[b.item.id] ?? false;
      if (aAll != bAll) return aAll ? -1 : 1;
      return b.score.compareTo(a.score);
    });

    return results.take(limit).toList();
  }
}
