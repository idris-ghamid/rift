import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class GeoDemoPage extends StatelessWidget {
  const GeoDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Geospatial',
      description: 'Geospatial queries with Haversine distance',
      codeExample:
          "GeoQuery.findWithinRadius(box, 'lat', 'lon', center, 1000);\nGeoQuery.findNearest(box, 'lat', 'lon', center, k: 5);",
      runDemo: () async {
        final box = await Rift.openBox<Map>('geo_demo');
        await box.clear();
        final buf = StringBuffer();
        buf.writeln('=== Geospatial Queries Demo ===\n');

        // Insert locations
        await box.putAll({
          'cairo': {'name': 'Cairo', 'lat': 30.0444, 'lon': 31.2357},
          'riyadh': {'name': 'Riyadh', 'lat': 24.7136, 'lon': 46.6753},
          'dubai': {'name': 'Dubai', 'lat': 25.2048, 'lon': 55.2708},
          'istanbul': {'name': 'Istanbul', 'lat': 41.0082, 'lon': 28.9784},
          'casablanca': {'name': 'Casablanca', 'lat': 33.5731, 'lon': -7.5898},
        });
        buf.writeln('Inserted 5 cities with coordinates\n');

        // Find within radius
        buf.writeln('--- Within 1000km of Cairo ---');
        final cairoCenter = const GeoPoint(30.0444, 31.2357);
        final withinRadius =
            GeoQuery.findWithinRadius(box, 'lat', 'lon', cairoCenter, 1000000);
        for (final r in withinRadius) {
          buf.writeln('  ${r.key}: ${r.distance.toStringAsFixed(0)}m away');
        }

        // Find nearest
        buf.writeln('\n--- 3 Nearest to Riyadh ---');
        final riyadhCenter = const GeoPoint(24.7136, 46.6753);
        final nearest =
            GeoQuery.findNearest(box, 'lat', 'lon', riyadhCenter, k: 3);
        for (final r in nearest) {
          buf.writeln('  ${r.key}: ${r.distance.toStringAsFixed(0)}m away');
        }

        // Bounding box
        buf.writeln('\n--- Bounding Box (20°-35°N, 25°-50°E) ---');
        final bbox = const GeoBoundingBox(20, 35, 25, 50);
        final inBox = GeoQuery.findInBoundingBox(box, 'lat', 'lon', bbox);
        for (final r in inBox) {
          buf.writeln(
              '  ${r.key}: ${r.point} (${r.distance.toStringAsFixed(0)}m from center)');
        }

        // Haversine distance
        buf.writeln('\n--- Haversine Distance ---');
        final dist = GeoQuery.haversineDistance(
          const GeoPoint(30.0444, 31.2357),
          const GeoPoint(24.7136, 46.6753),
        );
        buf.writeln(
            '  Cairo → Riyadh: ${dist.toStringAsFixed(0)}m (${(dist / 1000).toStringAsFixed(0)}km)');

        // Bounding box from radius
        buf.writeln('\n--- Bounding Box from 500km Radius ---');
        final radiusBox = GeoQuery.boundingBoxFromRadius(
            const GeoPoint(30.0444, 31.2357), 500000);
        buf.writeln('  $radiusBox');

        await box.close();
        return buf.toString();
      },
    );
  }
}
