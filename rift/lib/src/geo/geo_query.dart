import 'dart:math';

import 'package:rift/rift.dart';

/// Geospatial query support for Rift.
/// Allows searching by geographic proximity and bounding boxes.
class GeoQuery {
  /// Calculate distance between two points using Haversine formula.
  /// Returns the distance in meters.
  static double haversineDistance(GeoPoint a, GeoPoint b) {
    const R = 6371000; // Earth radius in meters
    final lat1 = a.latitude * pi / 180;
    final lat2 = b.latitude * pi / 180;
    final dLat = (b.latitude - a.latitude) * pi / 180;
    final dLon = (b.longitude - a.longitude) * pi / 180;
    final aVal =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(aVal), sqrt(1 - aVal));
    return R * c;
  }

  /// Find all points within a radius (in meters) from a center point.
  static List<GeoResult> findWithinRadius(
    Box box,
    String latField,
    String lonField,
    GeoPoint center,
    double radiusMeters,
  ) {
    final results = <GeoResult>[];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        final lat = value[latField];
        final lon = value[lonField];
        if (lat is num && lon is num) {
          final point = GeoPoint(lat.toDouble(), lon.toDouble());
          final distance = haversineDistance(center, point);
          if (distance <= radiusMeters) {
            results.add(GeoResult(key.toString(), point, distance));
          }
        }
      }
    }
    results.sort((a, b) => a.distance.compareTo(b.distance));
    return results;
  }

  /// Find all points within a bounding box.
  static List<GeoResult> findInBoundingBox(
    Box box,
    String latField,
    String lonField,
    GeoBoundingBox bbox,
  ) {
    final results = <GeoResult>[];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        final lat = value[latField];
        final lon = value[lonField];
        if (lat is num && lon is num) {
          final latD = lat.toDouble();
          final lonD = lon.toDouble();
          if (latD >= bbox.minLatitude &&
              latD <= bbox.maxLatitude &&
              lonD >= bbox.minLongitude &&
              lonD <= bbox.maxLongitude) {
            final point = GeoPoint(latD, lonD);
            final distance = haversineDistance(bbox.center, point);
            results.add(GeoResult(key.toString(), point, distance));
          }
        }
      }
    }
    results.sort((a, b) => a.distance.compareTo(b.distance));
    return results;
  }

  /// Find k nearest neighbors to a center point.
  static List<GeoResult> findNearest(
    Box box,
    String latField,
    String lonField,
    GeoPoint center, {
    int k = 10,
  }) {
    final allPoints = <GeoResult>[];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        final lat = value[latField];
        final lon = value[lonField];
        if (lat is num && lon is num) {
          final point = GeoPoint(lat.toDouble(), lon.toDouble());
          final distance = haversineDistance(center, point);
          allPoints.add(GeoResult(key.toString(), point, distance));
        }
      }
    }
    allPoints.sort((a, b) => a.distance.compareTo(b.distance));
    return allPoints.take(k).toList();
  }

  /// Count points within a radius from a center point.
  static int countWithinRadius(
    Box box,
    String latField,
    String lonField,
    GeoPoint center,
    double radiusMeters,
  ) {
    return findWithinRadius(
      box,
      latField,
      lonField,
      center,
      radiusMeters,
    ).length;
  }

  /// Check if a point is inside a bounding box.
  static bool isPointInBoundingBox(GeoPoint point, GeoBoundingBox bbox) {
    return point.latitude >= bbox.minLatitude &&
        point.latitude <= bbox.maxLatitude &&
        point.longitude >= bbox.minLongitude &&
        point.longitude <= bbox.maxLongitude;
  }

  /// Calculate the bounding box that contains all points within [radiusMeters]
  /// of [center]. Useful for pre-filtering before applying Haversine distance.
  static GeoBoundingBox boundingBoxFromRadius(
    GeoPoint center,
    double radiusMeters,
  ) {
    const R = 6371000.0;
    final latRad = center.latitude * pi / 180;
    final dLat = radiusMeters / R * 180 / pi;
    final dLon = radiusMeters / (R * cos(latRad)) * 180 / pi;

    return GeoBoundingBox(
      center.latitude - dLat,
      center.latitude + dLat,
      center.longitude - dLon,
      center.longitude + dLon,
    );
  }
}

/// A geographic coordinate point.
class GeoPoint {
  /// Latitude in degrees (-90 to 90).
  final double latitude;

  /// Longitude in degrees (-180 to 180).
  final double longitude;

  /// Create a geo point.
  const GeoPoint(this.latitude, this.longitude);

  @override
  bool operator ==(Object other) =>
      other is GeoPoint &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;

  @override
  String toString() => 'GeoPoint($latitude, $longitude)';
}

/// A geographic bounding box defined by latitude/longitude ranges.
class GeoBoundingBox {
  /// Minimum latitude (south boundary).
  final double minLatitude;

  /// Maximum latitude (north boundary).
  final double maxLatitude;

  /// Minimum longitude (west boundary).
  final double minLongitude;

  /// Maximum longitude (east boundary).
  final double maxLongitude;

  /// Create a bounding box.
  const GeoBoundingBox(
    this.minLatitude,
    this.maxLatitude,
    this.minLongitude,
    this.maxLongitude,
  );

  /// The center point of this bounding box.
  GeoPoint get center => GeoPoint(
    (minLatitude + maxLatitude) / 2,
    (minLongitude + maxLongitude) / 2,
  );

  /// Whether this bounding box contains the given [point].
  bool contains(GeoPoint point) {
    return point.latitude >= minLatitude &&
        point.latitude <= maxLatitude &&
        point.longitude >= minLongitude &&
        point.longitude <= maxLongitude;
  }

  /// Whether this bounding box overlaps with [other].
  bool overlaps(GeoBoundingBox other) {
    return minLatitude <= other.maxLatitude &&
        maxLatitude >= other.minLatitude &&
        minLongitude <= other.maxLongitude &&
        maxLongitude >= other.minLongitude;
  }

  @override
  String toString() =>
      'GeoBoundingBox(lat: $minLatitude..$maxLatitude, lon: $minLongitude..$maxLongitude)';
}

/// A result from a geospatial query.
class GeoResult {
  /// The key of the matching entry.
  final String key;

  /// The geographic point.
  final GeoPoint point;

  /// The distance from the query center in meters.
  final double distance;

  /// Create a geo result.
  GeoResult(this.key, this.point, this.distance);

  @override
  String toString() =>
      'GeoResult(key: $key, distance: ${distance.toStringAsFixed(1)}m)';
}
