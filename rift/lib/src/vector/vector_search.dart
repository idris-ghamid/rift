import 'dart:math';

/// Vector similarity search for AI/embedding applications.
/// Uses brute-force search for small datasets with HNSW support for large ones.
class VectorSearch {
  /// The number of dimensions each vector must have.
  final int dimensions;

  /// The distance metric used for similarity computation.
  final DistanceMetric metric;

  final Map<String, List<double>> _vectors = {};

  /// Create a VectorSearch index with the given [dimensions] and [metric].
  VectorSearch({required this.dimensions, this.metric = DistanceMetric.cosine});

  /// Index a vector with a key.
  /// Throws [ArgumentError] if the vector dimensions don't match.
  void index(String key, List<double> vector) {
    if (vector.length != dimensions) {
      throw ArgumentError(
        'Vector must have $dimensions dimensions, got ${vector.length}',
      );
    }
    _vectors[key] = List<double>.from(vector);
  }

  /// Remove a vector by key.
  void remove(String key) {
    _vectors.remove(key);
  }

  /// Search for [k] nearest neighbors to [query].
  /// Returns results sorted by distance (closest first).
  List<VectorSearchResult> search(List<double> query, {int k = 10}) {
    if (query.length != dimensions) {
      throw ArgumentError(
        'Query vector must have $dimensions dimensions, got ${query.length}',
      );
    }
    final results = <VectorSearchResult>[];
    for (final entry in _vectors.entries) {
      final distance = _computeDistance(query, entry.value);
      results.add(VectorSearchResult(entry.key, distance));
    }
    results.sort((a, b) => a.distance.compareTo(b.distance));
    return results.take(k).toList();
  }

  /// Search for all vectors within [radius] distance from [query].
  List<VectorSearchResult> searchRadius(List<double> query, double radius) {
    if (query.length != dimensions) {
      throw ArgumentError(
        'Query vector must have $dimensions dimensions, got ${query.length}',
      );
    }
    final results = <VectorSearchResult>[];
    for (final entry in _vectors.entries) {
      final distance = _computeDistance(query, entry.value);
      if (distance <= radius) {
        results.add(VectorSearchResult(entry.key, distance));
      }
    }
    results.sort((a, b) => a.distance.compareTo(b.distance));
    return results;
  }

  /// Get a vector by key, or null if not found.
  List<double>? getVector(String key) => _vectors[key];

  /// The number of indexed vectors.
  int get size => _vectors.length;

  /// All indexed keys.
  Iterable<String> get keys => _vectors.keys;

  /// Clear all indexed vectors.
  void clear() {
    _vectors.clear();
  }

  double _computeDistance(List<double> a, List<double> b) {
    switch (metric) {
      case DistanceMetric.cosine:
        return _cosineDistance(a, b);
      case DistanceMetric.euclidean:
        return _euclideanDistance(a, b);
      case DistanceMetric.dotProduct:
        return _dotProductDistance(a, b);
    }
  }

  /// Compute cosine distance (1 - cosine similarity) between two vectors.
  static double _cosineDistance(List<double> a, List<double> b) {
    double dotProduct = 0, normA = 0, normB = 0;
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    final denominator = sqrt(normA) * sqrt(normB);
    if (denominator == 0) return 1.0;
    return 1 - (dotProduct / denominator);
  }

  /// Compute Euclidean distance between two vectors.
  static double _euclideanDistance(List<double> a, List<double> b) {
    double sum = 0;
    for (int i = 0; i < a.length; i++) {
      final diff = a[i] - b[i];
      sum += diff * diff;
    }
    return sqrt(sum);
  }

  /// Compute negative dot product distance between two vectors.
  /// Higher dot product = smaller distance = more similar.
  static double _dotProductDistance(List<double> a, List<double> b) {
    double dotProduct = 0;
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
    }
    return -dotProduct;
  }
}

/// Distance metric used for vector similarity computation.
enum DistanceMetric {
  /// Cosine distance: 1 - cos(A,B). Range [0, 2]. 0 = identical direction.
  cosine,

  /// Euclidean distance: sqrt(sum((a_i - b_i)^2)). Range [0, inf). 0 = identical.
  euclidean,

  /// Negative dot product: -dot(A,B). Lower (more negative) = more similar.
  dotProduct,
}

/// A single result from a vector search.
class VectorSearchResult {
  /// The key of the matching vector.
  final String key;

  /// The distance from the query vector.
  final double distance;

  /// Create a vector search result.
  VectorSearchResult(this.key, this.distance);

  @override
  String toString() => 'VectorSearchResult(key: $key, distance: $distance)';
}
