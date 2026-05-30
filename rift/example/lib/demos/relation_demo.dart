import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class RelationDemoPage extends StatelessWidget {
  const RelationDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Relations',
      description: 'Relations between boxes with lazy loading',
      codeExample:
          "relManager.createRelation('users', RelationConfig(\n  field: 'posts', targetBox: 'posts', type: RelationType.oneToMany));\nawait relManager.getRelated('users', 'u1', 'posts');",
      runDemo: () async {
        final usersBox = await Rift.openBox<Map>('users_rel');
        final postsBox = await Rift.openBox<Map>('posts_rel');
        await usersBox.clear();
        await postsBox.clear();

        final buf = StringBuffer();
        buf.writeln('=== Relations Demo ===\n');

        // Create relation manager
        final relManager = RelationManager();
        relManager.createRelation(
            'users',
            RelationConfig(
              field: 'posts',
              targetBox: 'posts_rel',
              targetField: 'authorId',
              type: RelationType.oneToMany,
              lazyLoad: true,
              cascadeDelete: false,
            ));

        // Insert users
        await usersBox.putAll({
          'u1': {'name': 'Alice'},
          'u2': {'name': 'Bob'},
        });

        // Insert posts with foreign key
        await postsBox.putAll({
          'p1': {'title': 'Hello World', 'authorId': 'u1'},
          'p2': {'title': 'Dart Tips', 'authorId': 'u1'},
          'p3': {'title': 'Flutter Guide', 'authorId': 'u2'},
        });

        // Update relation indexes
        for (final k in postsBox.keys) {
          relManager.onPut('posts_rel', k, postsBox.get(k));
        }

        buf.writeln('Users: ${usersBox.toMap()}');
        buf.writeln('Posts: ${postsBox.toMap()}\n');

        // Query relations
        buf.writeln('--- Alice\'s Posts (u1) ---');
        final alicePosts = await relManager.getRelated('users', 'u1', 'posts');
        buf.writeln('  Found ${alicePosts.length} posts: $alicePosts');

        buf.writeln('\n--- Bob\'s Posts (u2) ---');
        final bobPosts = await relManager.getRelated('users', 'u2', 'posts');
        buf.writeln('  Found ${bobPosts.length} posts: $bobPosts');

        // Many-to-many
        buf.writeln('\n--- Many-to-Many: Tags ---');
        relManager.createRelation(
            'posts',
            RelationConfig(
              field: 'tags',
              targetBox: 'tags_rel',
              targetField: 'id',
              type: RelationType.manyToMany,
            ));
        await relManager.setRelated('posts', 'p1', 'tags', ['dart', 'hello']);
        await relManager.setRelated('posts', 'p2', 'tags', ['dart', 'tips']);
        buf.writeln('  Post p1 tags: dart, hello');
        buf.writeln('  Post p2 tags: dart, tips');

        buf.writeln('\n--- Relation Configs ---');
        for (final config in relManager.getRelations('users')) {
          buf.writeln(
              '  ${config.field} → ${config.targetBox} (${config.type})');
        }

        await usersBox.close();
        await postsBox.close();
        return buf.toString();
      },
    );
  }
}
