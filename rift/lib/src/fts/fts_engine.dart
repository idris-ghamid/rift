import 'dart:collection';
import 'dart:math';

import 'package:rift/src/fts/fts_result.dart';
import 'package:rift/src/rift_error.dart';

/// Operator for combining search terms in a full-text search query.
enum FTSSearchOperator {
  /// All terms must be present (AND logic).
  and,

  /// At least one term must be present (OR logic).
  or,

  /// The terms must appear as an exact phrase.
  phrase,
}

/// A full-text search query that specifies what to search for and how.
class FTSQuery {
  /// The search terms to look for.
  final List<String> terms;

  /// Terms to exclude from results (NOT operator).
  final List<String> notTerms;

  /// How to combine the search terms.
  final FTSSearchOperator operator;

  /// Restrict search to these field names. If empty, all fields are searched.
  final List<String> fields;

  /// Maximum number of results to return. Use 0 for unlimited.
  final int limit;

  /// Minimum score threshold. Results with scores below this are excluded.
  final double minScore;

  /// Whether to include snippets in results.
  final bool includeSnippets;

  /// Creates a new [FTSQuery].
  const FTSQuery({
    required this.terms,
    this.notTerms = const [],
    this.operator = FTSSearchOperator.and,
    this.fields = const [],
    this.limit = 100,
    this.minScore = 0.0,
    this.includeSnippets = true,
  });

  /// Creates a query from a text string.
  factory FTSQuery.parse(String queryText) {
    final terms = <String>[];
    final notTerms = <String>[];
    FTSSearchOperator op = FTSSearchOperator.or;

    final parts = queryText.split(RegExp(r'\s+'));
    for (final part in parts) {
      if (part.startsWith('-') && part.length > 1) {
        notTerms.add(part.substring(1));
      } else if (part == 'AND') {
        op = FTSSearchOperator.and;
      } else if (part == 'OR') {
        op = FTSSearchOperator.or;
      } else if (part.startsWith('"') &&
          part.endsWith('"') &&
          part.length > 2) {
        op = FTSSearchOperator.phrase;
        terms.add(part.substring(1, part.length - 1));
      } else if (part.isNotEmpty) {
        terms.add(part);
      }
    }

    return FTSQuery(terms: terms, notTerms: notTerms, operator: op);
  }
}

/// An entry in the inverted index mapping a token to a document and position.
class _IndexEntry {
  final String docKey;
  final String field;
  final int position;
  _IndexEntry(this.docKey, this.field, this.position);
}

/// A document stored in the FTS engine with its field contents.
class _FTSDocument {
  final String key;
  final Map<String, String> fields;
  final Map<String, List<String>> tokenizedFields;
  _FTSDocument(this.key, this.fields, this.tokenizedFields);
}

/// Full-text search engine with inverted index, TF-IDF scoring,
/// and basic English stemming.
///
/// Usage:
/// ```dart
/// final engine = FTSEngine();
/// engine.indexDocument('doc1', {
///   'title': 'Introduction to Dart',
///   'body': 'Dart is a client-optimized language for fast apps.',
/// });
/// final results = engine.search(FTSQuery(
///   terms: ['dart', 'language'],
///   operator: FTSSearchOperator.and,
/// ));
/// ```
class FTSEngine {
  final Map<String, List<_IndexEntry>> _invertedIndex = {};
  final Map<String, _FTSDocument> _documents = {};

  int get documentCount => _documents.length;
  int get tokenCount => _invertedIndex.length;

  int get entryCount {
    var count = 0;
    for (final entries in _invertedIndex.values) {
      count += entries.length;
    }
    return count;
  }

  static const Set<String> _stopWords = {
    'a',
    'an',
    'the',
    'and',
    'or',
    'but',
    'in',
    'on',
    'at',
    'to',
    'for',
    'of',
    'with',
    'by',
    'from',
    'is',
    'it',
    'its',
    'was',
    'were',
    'be',
    'been',
    'being',
    'have',
    'has',
    'had',
    'do',
    'does',
    'did',
    'will',
    'would',
    'could',
    'should',
    'may',
    'might',
    'can',
    'shall',
    'not',
    'no',
    'nor',
    'so',
    'if',
    'then',
    'than',
    'too',
    'very',
    'just',
    'about',
    'above',
    'after',
    'again',
    'all',
    'also',
    'am',
    'as',
    'because',
    'before',
    'between',
    'both',
    'each',
    'few',
    'get',
    'got',
    'he',
    'her',
    'here',
    'him',
    'his',
    'how',
    'i',
    'into',
    'me',
    'more',
    'most',
    'my',
    'now',
    'only',
    'other',
    'our',
    'out',
    'over',
    'own',
    'same',
    'she',
    'some',
    'such',
    'that',
    'their',
    'them',
    'there',
    'these',
    'they',
    'this',
    'those',
    'through',
    'up',
    'us',
    'we',
    'what',
    'when',
    'where',
    'which',
    'while',
    'who',
    'whom',
    'why',
    'you',
    'your',
  };

  /// Tokenizes the input [text] into a list of normalized tokens.
  List<String> tokenize(String text) {
    final buffer = StringBuffer();
    final tokens = <String>[];

    for (int i = 0; i < text.length; i++) {
      final codeUnit = text.codeUnitAt(i);
      if (_isAlphanumeric(codeUnit)) {
        buffer.writeCharCode(codeUnit);
      } else {
        _flushBuffer(buffer, tokens);
      }
    }
    _flushBuffer(buffer, tokens);

    final result = <String>[];
    for (final token in tokens) {
      final lower = token.toLowerCase();
      if (lower.length < 2) continue;
      if (_stopWords.contains(lower)) continue;
      result.add(stem(lower));
    }
    return result;
  }

  void _flushBuffer(StringBuffer buffer, List<String> tokens) {
    if (buffer.isNotEmpty) {
      tokens.add(buffer.toString());
      buffer.clear();
    }
  }

  bool _isAlphanumeric(int codeUnit) {
    return (codeUnit >= 0x30 && codeUnit <= 0x39) ||
        (codeUnit >= 0x41 && codeUnit <= 0x5A) ||
        (codeUnit >= 0x61 && codeUnit <= 0x7A) ||
        (codeUnit >= 0xC0 && codeUnit <= 0xFF) ||
        (codeUnit >= 0x100 && codeUnit <= 0x1FF) ||
        codeUnit == 0x5F;
  }

  /// Applies a simplified Porter stemmer to the given [word].
  String stem(String word) {
    if (word.length < 3) return word;
    var s = word;

    // Step 1a: Plural forms
    if (s.endsWith('sses')) {
      s = s.substring(0, s.length - 2);
    } else if (s.endsWith('ies')) {
      s = s.substring(0, s.length - 2);
    } else if (s.endsWith('ss')) {
      // Keep as-is
    } else if (s.endsWith('s') && !s.endsWith('us') && !s.endsWith('ss')) {
      s = s.substring(0, s.length - 1);
    }

    // Step 1b
    if (s.endsWith('eed')) {
      final stem = s.substring(0, s.length - 3);
      if (_measure(stem) > 0) s = s.substring(0, s.length - 1);
    } else if (s.endsWith('ed') && _hasVowel(s.substring(0, s.length - 2))) {
      s = s.substring(0, s.length - 2);
      s = _step1bCleanup(s);
    } else if (s.endsWith('ing') && _hasVowel(s.substring(0, s.length - 3))) {
      s = s.substring(0, s.length - 3);
      s = _step1bCleanup(s);
    }

    // Step 1c: y -> i
    if (s.endsWith('y') &&
        s.length > 2 &&
        _hasVowel(s.substring(0, s.length - 1))) {
      s = '${s.substring(0, s.length - 1)}i';
    }

    // Step 2
    final step2 = {
      'ational': 'ate',
      'tional': 'tion',
      'enci': 'ence',
      'anci': 'ance',
      'izer': 'ize',
      'abli': 'able',
      'alli': 'al',
      'entli': 'ent',
      'eli': 'e',
      'ousli': 'ous',
      'ization': 'ize',
      'ation': 'ate',
      'ator': 'ate',
      'alism': 'al',
      'iveness': 'ive',
      'fulness': 'ful',
      'ousness': 'ous',
      'aliti': 'al',
      'iviti': 'ive',
      'biliti': 'ble',
    };
    for (final e in step2.entries) {
      if (s.endsWith(e.key)) {
        final stem = s.substring(0, s.length - e.key.length);
        if (_measure(stem) > 0) s = stem + e.value;
        break;
      }
    }

    // Step 3
    final step3 = {
      'icate': 'ic',
      'ative': '',
      'alize': 'al',
      'iciti': 'ic',
      'ical': 'ic',
      'ful': '',
      'ness': '',
    };
    for (final e in step3.entries) {
      if (s.endsWith(e.key)) {
        final stem = s.substring(0, s.length - e.key.length);
        if (_measure(stem) > 0) s = stem + e.value;
        break;
      }
    }

    // Step 4
    const step4 = [
      'al',
      'ance',
      'ence',
      'er',
      'ic',
      'able',
      'ible',
      'ant',
      'ement',
      'ment',
      'ent',
      'ion',
      'ou',
      'ism',
      'ate',
      'iti',
      'ous',
      'ive',
      'ize',
    ];
    for (final suffix in step4) {
      if (s.endsWith(suffix)) {
        final stem = s.substring(0, s.length - suffix.length);
        if (_measure(stem) > 1) {
          if (suffix == 'ion') {
            if (stem.isNotEmpty && (stem.endsWith('s') || stem.endsWith('t'))) {
              s = stem;
            }
          } else {
            s = stem;
          }
        }
        break;
      }
    }

    // Step 5a
    if (s.endsWith('e')) {
      final stem = s.substring(0, s.length - 1);
      if (_measure(stem) > 1 || (_measure(stem) == 1 && !_endsWithCVC(stem))) {
        s = stem;
      }
    }

    // Step 5b
    if (s.length > 2 &&
        s[s.length - 1] == s[s.length - 2] &&
        _isConsonant(s, s.length - 1) &&
        s[s.length - 1] != 's' &&
        s[s.length - 1] != 'z') {
      s = s.substring(0, s.length - 1);
    }

    return s;
  }

  String _step1bCleanup(String s) {
    if (s.endsWith('at') || s.endsWith('bl') || s.endsWith('iz')) {
      return '${s}e';
    }
    if (s.length > 2 &&
        _isConsonant(s, s.length - 1) &&
        s[s.length - 1] == s[s.length - 2] &&
        s[s.length - 1] != 'l' &&
        s[s.length - 1] != 's' &&
        s[s.length - 1] != 'z') {
      return s.substring(0, s.length - 1);
    }
    if (_measure(s) == 1 && _endsWithCVC(s)) return '${s}e';
    return s;
  }

  int _measure(String s) {
    if (s.isEmpty) return 0;
    var m = 0;
    var i = 0;
    while (i < s.length && _isConsonant(s, i)) {
      i++;
    }
    while (i < s.length) {
      while (i < s.length && !_isConsonant(s, i)) {
        i++;
      }
      if (i >= s.length) break;
      while (i < s.length && _isConsonant(s, i)) {
        i++;
      }
      m++;
    }
    return m;
  }

  bool _isConsonant(String s, int i) {
    if (i < 0 || i >= s.length) return false;
    final c = s[i].toLowerCase();
    if (c == 'a' || c == 'e' || c == 'i' || c == 'o' || c == 'u') return false;
    if (c == 'y') return i == 0 || !_isConsonant(s, i - 1);
    return true;
  }

  bool _hasVowel(String s) {
    for (int i = 0; i < s.length; i++) {
      if (!_isConsonant(s, i)) return true;
    }
    return false;
  }

  bool _endsWithCVC(String s) {
    if (s.length < 3) return false;
    final i = s.length - 1;
    return _isConsonant(s, i) &&
        !_isConsonant(s, i - 1) &&
        _isConsonant(s, i - 2) &&
        s[i] != 'w' &&
        s[i] != 'x' &&
        s[i] != 'y';
  }

  /// Indexes a document with the given [key] and [fields].
  void indexDocument(String key, Map<String, String> fields) {
    if (_documents.containsKey(key)) removeDocument(key);

    final tokenizedFields = <String, List<String>>{};
    for (final entry in fields.entries) {
      tokenizedFields[entry.key] = tokenize(entry.value);
    }

    final doc = _FTSDocument(
      key,
      Map<String, String>.from(fields),
      tokenizedFields,
    );
    _documents[key] = doc;

    for (final fieldEntry in tokenizedFields.entries) {
      final fieldName = fieldEntry.key;
      final tokens = fieldEntry.value;
      for (int pos = 0; pos < tokens.length; pos++) {
        final token = tokens[pos];
        _invertedIndex
            .putIfAbsent(token, () => [])
            .add(_IndexEntry(key, fieldName, pos));
      }
    }
  }

  /// Removes a document from the index by its [key].
  void removeDocument(String key) {
    final doc = _documents[key];
    if (doc == null) throw RiftError('Document $key not found in FTS index');

    final emptyTokens = <String>[];
    for (final entry in _invertedIndex.entries) {
      entry.value.removeWhere((e) => e.docKey == key);
      if (entry.value.isEmpty) emptyTokens.add(entry.key);
    }
    for (final token in emptyTokens) {
      _invertedIndex.remove(token);
    }
    _documents.remove(key);
  }

  /// Checks whether a document with the given [key] is indexed.
  bool containsDocument(String key) => _documents.containsKey(key);

  /// Executes a full-text search query and returns ranked results.
  List<FTSResult> search(FTSQuery query) {
    if (query.terms.isEmpty) return [];

    final stemmedTerms = query.terms.map((t) => stem(t.toLowerCase())).toList();

    Map<String, Map<String, List<int>>> matchData;
    switch (query.operator) {
      case FTSSearchOperator.and:
        matchData = _searchAnd(stemmedTerms, query.fields);
      case FTSSearchOperator.or:
        matchData = _searchOr(stemmedTerms, query.fields);
      case FTSSearchOperator.phrase:
        matchData = _searchPhrase(stemmedTerms, query.fields);
    }

    // Handle NOT terms
    if (query.notTerms.isNotEmpty) {
      final excludedDocs = <String>{};
      for (final notTerm in query.notTerms) {
        final stemmed = stem(notTerm.toLowerCase());
        final entries = _invertedIndex[stemmed];
        if (entries != null) {
          for (final entry in entries) {
            excludedDocs.add(entry.docKey);
          }
        }
      }
      matchData.removeWhere((key, _) => excludedDocs.contains(key));
    }

    if (matchData.isEmpty) return [];

    final results = <FTSResult>[];
    final totalDocs = _documents.length.toDouble();

    for (final docEntry in matchData.entries) {
      final docKey = docEntry.key;
      final fieldPositions = docEntry.value;
      final doc = _documents[docKey];
      if (doc == null) continue;

      double score = 0.0;
      for (final term in stemmedTerms) {
        final tf = fieldPositions.values.expand((p) => p).length.toDouble();
        final df =
            _invertedIndex[term]?.map((e) => e.docKey).toSet().length ?? 0;
        final idf = df > 0 ? log(totalDocs / df.toDouble()) : 0.0;
        score += tf * idf;
      }

      if (query.operator == FTSSearchOperator.phrase) score *= 1.5;

      final snippet = query.includeSnippets
          ? _generateSnippet(doc, fieldPositions, stemmedTerms)
          : '';

      if (score >= query.minScore) {
        results.add(
          FTSResult(
            key: docKey,
            score: score,
            fieldPositions: Map<String, List<int>>.from(
              fieldPositions.map((k, v) => MapEntry(k, List<int>.from(v))),
            ),
            snippet: snippet,
          ),
        );
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    if (query.limit > 0 && results.length > query.limit) {
      return results.sublist(0, query.limit);
    }
    return results;
  }

  Map<String, Map<String, List<int>>> _searchAnd(
    List<String> stemmedTerms,
    List<String> restrictedFields,
  ) {
    final termDocs = <String, Set<String>>{};
    final termPositions = <String, Map<String, Map<String, List<int>>>>{};

    for (final term in stemmedTerms) {
      final entries = _invertedIndex[term];
      if (entries == null || entries.isEmpty) return {};

      final docKeys = <String>{};
      final positions = <String, Map<String, List<int>>>{};

      for (final entry in entries) {
        if (restrictedFields.isNotEmpty &&
            !restrictedFields.contains(entry.field)) {
          continue;
        }
        docKeys.add(entry.docKey);
        positions.putIfAbsent(entry.docKey, () => {});
        positions[entry.docKey]!.putIfAbsent(entry.field, () => []);
        positions[entry.docKey]![entry.field]!.add(entry.position);
      }

      if (docKeys.isEmpty) return {};
      termDocs[term] = docKeys;
      termPositions[term] = positions;
    }

    var intersection = termDocs.values.first;
    for (final docs in termDocs.values) {
      intersection = intersection.intersection(docs);
    }

    final result = <String, Map<String, List<int>>>{};
    for (final docKey in intersection) {
      final merged = <String, List<int>>{};
      for (final term in stemmedTerms) {
        final dp = termPositions[term]?[docKey];
        if (dp != null) {
          for (final fe in dp.entries) {
            merged.putIfAbsent(fe.key, () => []);
            merged[fe.key]!.addAll(fe.value);
          }
        }
      }
      for (final field in merged.keys) {
        merged[field] = merged[field]!.toSet().toList()..sort();
      }
      result[docKey] = merged;
    }
    return result;
  }

  Map<String, Map<String, List<int>>> _searchOr(
    List<String> stemmedTerms,
    List<String> restrictedFields,
  ) {
    final result = <String, Map<String, List<int>>>{};

    for (final term in stemmedTerms) {
      final entries = _invertedIndex[term];
      if (entries == null) continue;

      for (final entry in entries) {
        if (restrictedFields.isNotEmpty &&
            !restrictedFields.contains(entry.field)) {
          continue;
        }
        result.putIfAbsent(entry.docKey, () => {});
        result[entry.docKey]!.putIfAbsent(entry.field, () => []);
        result[entry.docKey]![entry.field]!.add(entry.position);
      }
    }

    for (final dp in result.values) {
      for (final field in dp.keys) {
        dp[field] = dp[field]!.toSet().toList()..sort();
      }
    }
    return result;
  }

  Map<String, Map<String, List<int>>> _searchPhrase(
    List<String> stemmedTerms,
    List<String> restrictedFields,
  ) {
    if (stemmedTerms.length == 1) {
      return _searchOr(stemmedTerms, restrictedFields);
    }

    final firstEntries = _invertedIndex[stemmedTerms.first];
    if (firstEntries == null || firstEntries.isEmpty) return {};

    final result = <String, Map<String, List<int>>>{};

    for (final firstEntry in firstEntries) {
      if (restrictedFields.isNotEmpty &&
          !restrictedFields.contains(firstEntry.field)) {
        continue;
      }

      final docKey = firstEntry.docKey;
      final field = firstEntry.field;
      final startPos = firstEntry.position;

      var isPhrase = true;
      for (int i = 1; i < stemmedTerms.length; i++) {
        final entries = _invertedIndex[stemmedTerms[i]];
        if (entries == null) {
          isPhrase = false;
          break;
        }
        if (!entries.any(
          (e) =>
              e.docKey == docKey &&
              e.field == field &&
              e.position == startPos + i,
        )) {
          isPhrase = false;
          break;
        }
      }

      if (isPhrase) {
        result.putIfAbsent(docKey, () => {});
        result[docKey]!.putIfAbsent(field, () => []);
        result[docKey]![field]!.add(startPos);
      }
    }
    return result;
  }

  String _generateSnippet(
    _FTSDocument doc,
    Map<String, List<int>> fieldPositions,
    List<String> stemmedTerms,
  ) {
    const snippetLength = 80;
    String? bestField;
    int bestCount = 0;
    for (final entry in fieldPositions.entries) {
      if (entry.value.length > bestCount) {
        bestCount = entry.value.length;
        bestField = entry.key;
      }
    }
    if (bestField == null) return '';

    final text = doc.fields[bestField] ?? '';
    if (text.isEmpty) return '';

    final tokens = tokenize(text);
    final firstMatchPos = fieldPositions[bestField]?.firstOrNull ?? 0;

    int charOffset = 0;
    for (int i = 0; i < firstMatchPos && i < tokens.length; i++) {
      charOffset += tokens[i].length + 1;
    }

    final start = (charOffset - snippetLength ~/ 2).clamp(0, text.length);
    final end = (start + snippetLength).clamp(0, text.length);

    var snippet = text.substring(start, end);
    if (start > 0) snippet = '...$snippet';
    if (end < text.length) snippet = '$snippet...';
    return snippet;
  }

  /// Clears the entire FTS index.
  void clear() {
    _invertedIndex.clear();
    _documents.clear();
  }

  /// Returns statistics about the FTS index.
  Map<String, dynamic> getStats() {
    return {
      'documentCount': documentCount,
      'tokenCount': tokenCount,
      'entryCount': entryCount,
      'avgEntriesPerToken': tokenCount > 0
          ? (entryCount / tokenCount).toStringAsFixed(2)
          : '0',
    };
  }
}
