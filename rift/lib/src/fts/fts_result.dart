import 'package:meta/meta.dart';

/// Represents a single search result from a full-text search query.
///
/// Contains the document key, relevance score, positions of matches
/// within each field, and a contextual snippet around the best match.
@immutable
class FTSResult {
  /// The key of the matching document.
  final String key;

  /// The relevance score of this result (higher is more relevant).
  /// Computed using TF-IDF ranking.
  final double score;

  /// A map from field name to the list of token positions where
  /// matches were found in that field.
  final Map<String, List<int>> fieldPositions;

  /// A short snippet of text surrounding the best match, useful for
  /// displaying search result previews.
  final String snippet;

  /// Creates a new [FTSResult].
  const FTSResult({
    required this.key,
    required this.score,
    required this.fieldPositions,
    required this.snippet,
  });

  /// The total number of matches across all fields.
  int get totalMatches {
    var count = 0;
    for (final positions in fieldPositions.values) {
      count += positions.length;
    }
    return count;
  }

  /// The field with the most matches, or null if no matches.
  String? get bestField {
    String? best;
    var bestCount = 0;
    for (final entry in fieldPositions.entries) {
      if (entry.value.length > bestCount) {
        bestCount = entry.value.length;
        best = entry.key;
      }
    }
    return best;
  }

  @override
  bool operator ==(Object other) {
    if (other is FTSResult) {
      return other.key == key && other.score == score;
    }
    return false;
  }

  @override
  int get hashCode => key.hashCode ^ score.hashCode;

  @override
  String toString() =>
      'FTSResult(key: $key, score: $score, '
      'matches: $totalMatches, snippet: ${snippet.length > 40 ? '${snippet.substring(0, 40)}...' : snippet})';
}
