enum SearchableItemType { faq, setting }

class SearchableItem {
  final String id;
  final SearchableItemType type;
  final String question;
  final String answer;
  final List<String> keywords;
  final List<String> path; // breadcrumb, e.g. ['Settings', 'Invoice Settings', 'Tax & GST']

  const SearchableItem({
    required this.id,
    required this.type,
    required this.question,
    required this.answer,
    required this.keywords,
    this.path = const [],
  });

  String get pathLabel => path.join(' → ');
}

class ScoredSearchResult {
  final SearchableItem item;
  final int score; // 0-100 fuzzy match score

  const ScoredSearchResult(this.item, this.score);
}
