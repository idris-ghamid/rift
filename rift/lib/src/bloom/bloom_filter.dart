import 'dart:math';

/// Bloom filter for fast key existence checking.
/// Reduces disk I/O by quickly determining if a key definitely doesn't exist.
///
/// A bloom filter can tell you with certainty that a key is NOT in a set,
/// but may give false positives (say a key IS present when it isn't).
/// It never gives false negatives.
class BloomFilter {
  final List<int> _bits;
  final int _size;
  final int _numHashes;
  int _count = 0;

  /// Create a bloom filter optimized for [expectedItems] items
  /// with a target [falsePositiveRate] (default 1%).
  BloomFilter({int expectedItems = 10000, double falsePositiveRate = 0.01})
    : _size = _optimalSize(expectedItems, falsePositiveRate),
      _numHashes = _optimalHashes(
        expectedItems,
        _optimalSize(expectedItems, falsePositiveRate),
      ),
      _bits = List.filled(
        (_optimalSize(expectedItems, falsePositiveRate) ~/ 32) + 1,
        0,
      );

  BloomFilter._(this._size, this._numHashes, this._bits);

  /// Add a key to the filter.
  void add(String key) {
    for (int i = 0; i < _numHashes; i++) {
      final hash = _hash(key, i);
      final index = hash % _size;
      _bits[index ~/ 32] |= (1 << (index % 32));
    }
    _count++;
  }

  /// Check if a key might exist.
  /// Returns true if the key might be in the set (may be a false positive).
  /// Returns false if the key is definitely not in the set (never a false negative).
  bool mightContain(String key) {
    for (int i = 0; i < _numHashes; i++) {
      final hash = _hash(key, i);
      final index = hash % _size;
      if ((_bits[index ~/ 32] & (1 << (index % 32))) == 0) return false;
    }
    return true;
  }

  /// Number of items that have been added.
  int get count => _count;

  /// The size of the bit array.
  int get bitSize => _size;

  /// Number of hash functions used.
  int get numHashes => _numHashes;

  /// The expected false positive rate based on the current count.
  double get expectedFalsePositiveRate {
    if (_count == 0) return 0;
    return pow(1 - exp(-_numHashes * _count / _size), _numHashes).toDouble();
  }

  /// The fill ratio (fraction of bits set to 1).
  double get fillRatio {
    int setBits = 0;
    for (int i = 0; i < _size; i++) {
      if ((_bits[i ~/ 32] & (1 << (i % 32))) != 0) setBits++;
    }
    return setBits / _size;
  }

  /// Reset the bloom filter (remove all entries).
  void clear() {
    for (int i = 0; i < _bits.length; i++) {
      _bits[i] = 0;
    }
    _count = 0;
  }

  /// Merge with another bloom filter (bitwise OR).
  /// Both filters must have the same size and number of hashes.
  BloomFilter merge(BloomFilter other) {
    if (_size != other._size || _numHashes != other._numHashes) {
      throw ArgumentError(
        'Cannot merge bloom filters with different configurations',
      );
    }
    final mergedBits = List<int>.filled(_bits.length, 0);
    for (int i = 0; i < _bits.length; i++) {
      mergedBits[i] = _bits[i] | other._bits[i];
    }
    final result = BloomFilter._(_size, _numHashes, mergedBits);
    result._count = max(_count, other._count);
    return result;
  }

  /// Serialize the bloom filter to bytes.
  List<int> toBytes() {
    final bytes = <int>[];
    // Header: size (4 bytes), numHashes (4 bytes), count (4 bytes)
    bytes.addAll(_intToBytes(_size));
    bytes.addAll(_intToBytes(_numHashes));
    bytes.addAll(_intToBytes(_count));
    // Bits
    for (final word in _bits) {
      bytes.addAll(_intToBytes(word));
    }
    return bytes;
  }

  /// Deserialize a bloom filter from bytes.
  static BloomFilter fromBytes(List<int> bytes) {
    int offset = 0;
    final size = _bytesToInt(bytes, offset);
    offset += 4;
    final numHashes = _bytesToInt(bytes, offset);
    offset += 4;
    final count = _bytesToInt(bytes, offset);
    offset += 4;

    final bitsLength = (size ~/ 32) + 1;
    final bits = List<int>.filled(bitsLength, 0);
    for (int i = 0; i < bitsLength; i++) {
      bits[i] = _bytesToInt(bytes, offset);
      offset += 4;
    }

    final filter = BloomFilter._(size, numHashes, bits);
    filter._count = count;
    return filter;
  }

  /// Double hashing technique for generating multiple hash values.
  int _hash(String key, int seed) {
    int hash1 = _murmurHash(key, 0);
    int hash2 = _murmurHash(key, hash1);
    return (hash1 + seed * hash2) & 0x7FFFFFFF;
  }

  /// Simplified MurmurHash implementation.
  static int _murmurHash(String key, int seed) {
    int h = seed;
    for (int i = 0; i < key.length; i++) {
      h ^= key.codeUnitAt(i);
      h = (h * 0x5BD1E995) & 0xFFFFFFFF;
      h ^= h >> 15;
    }
    return h & 0x7FFFFFFF;
  }

  /// Calculate optimal bit array size for [n] items and [p] false positive rate.
  static int _optimalSize(int n, double p) =>
      (-n * log(p) / (ln2 * ln2)).ceil();

  /// Calculate optimal number of hash functions for [n] items and [m] bits.
  static int _optimalHashes(int n, int m) => (m / n * ln2).ceil().clamp(1, 20);

  static List<int> _intToBytes(int value) {
    return [
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    ];
  }

  static int _bytesToInt(List<int> bytes, int offset) {
    return (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
  }
}
