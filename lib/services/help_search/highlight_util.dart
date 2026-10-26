import 'package:flutter/material.dart';

/// Finds merged, sorted [start, end) ranges in [text] where any of
/// [queryWords] occurs (case-insensitive substring match).
List<(int, int)> findHighlightRanges(String text, Iterable<String> queryWords) {
  final lowerText = text.toLowerCase();
  final ranges = <(int, int)>[];

  for (final raw in queryWords) {
    final word = raw.toLowerCase().trim();
    if (word.isEmpty) continue;
    var start = 0;
    while (true) {
      final idx = lowerText.indexOf(word, start);
      if (idx == -1) break;
      ranges.add((idx, idx + word.length));
      start = idx + word.length;
    }
  }

  if (ranges.isEmpty) return ranges;
  ranges.sort((a, b) => a.$1.compareTo(b.$1));

  final merged = <(int, int)>[ranges.first];
  for (final r in ranges.skip(1)) {
    final last = merged.last;
    if (r.$1 <= last.$2) {
      merged[merged.length - 1] = (last.$1, r.$2 > last.$2 ? r.$2 : last.$2);
    } else {
      merged.add(r);
    }
  }
  return merged;
}

/// Builds a [TextSpan] for [text] with any [queryWords] matches bolded and
/// given a soft highlight background, using [baseStyle] for the rest.
TextSpan highlightedTextSpan(
  String text,
  Set<String> queryWords, {
  required TextStyle? baseStyle,
  required Color highlightColor,
}) {
  final ranges = findHighlightRanges(text, queryWords);
  if (ranges.isEmpty) return TextSpan(text: text, style: baseStyle);

  final highlightStyle = baseStyle?.copyWith(
    fontWeight: FontWeight.w800,
    backgroundColor: highlightColor,
  );

  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final (start, end) in ranges) {
    if (start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, start), style: baseStyle));
    }
    spans.add(TextSpan(text: text.substring(start, end), style: highlightStyle));
    cursor = end;
  }
  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
  }
  return TextSpan(children: spans);
}

final _emphasisPattern = RegExp(r'\*\*(.+?)\*\*');

/// Parses lightweight `**bold**` markup authored into an answer's text —
/// for calling out the specific detail that matters (a value, a name, a
/// warning) regardless of what the user searched for. Distinct from
/// [highlightedTextSpan], which highlights the user's own query terms.
TextSpan parseEmphasisSpans(
  String text, {
  required TextStyle? baseStyle,
  required TextStyle? emphasisStyle,
}) {
  final matches = _emphasisPattern.allMatches(text).toList();
  if (matches.isEmpty) return TextSpan(text: text, style: baseStyle);

  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final m in matches) {
    if (m.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, m.start), style: baseStyle));
    }
    spans.add(TextSpan(text: m.group(1), style: emphasisStyle));
    cursor = m.end;
  }
  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
  }
  return TextSpan(children: spans);
}
