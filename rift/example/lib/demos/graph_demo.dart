import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class GraphDemoPage extends StatelessWidget {
  const GraphDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Graph Traversal',
      description: 'Graph traversal for complex relationships',
      codeExample:
          "relManager.createRelation('box', RelationConfig(\n  type: RelationType.manyToMany));\nawait relManager.getRelated('box', key, 'field');",
      runDemo: () async {
        final box = await Rift.openBox<Map>('graph_demo');
        await box.clear();
        final buf = StringBuffer();
        buf.writeln('=== Graph Traversal Demo ===\n');

        // Build a social graph using box data + relation indexes
        await box.putAll({
          'alice': {'name': 'Alice', 'type': 'person'},
          'bob': {'name': 'Bob', 'type': 'person'},
          'charlie': {'name': 'Charlie', 'type': 'person'},
          'diana': {'name': 'Diana', 'type': 'person'},
          'team1': {'name': 'Engineering', 'type': 'team'},
          'team2': {'name': 'Design', 'type': 'team'},
        });

        // Use relations as edges
        final relManager = RelationManager();
        relManager.createRelation(
            'graph_demo',
            RelationConfig(
              field: 'members',
              targetBox: 'graph_demo',
              targetField: 'teamId',
              type: RelationType.manyToMany,
            ));

        // Add edges (person → team)
        await relManager.setRelated(
            'graph_demo', 'team1', 'members', ['alice', 'bob', 'charlie']);
        await relManager
            .setRelated('graph_demo', 'team2', 'members', ['diana', 'charlie']);

        buf.writeln('Graph: 4 people, 2 teams');
        buf.writeln('  team1 (Engineering): Alice, Bob, Charlie');
        buf.writeln('  team2 (Design): Diana, Charlie\n');

        // Query: find shared members
        buf.writeln('--- Traversal: Alice\'s teammates ---');
        final team1Members =
            await relManager.getRelated('graph_demo', 'team1', 'members');
        buf.writeln('  Team1 members: $team1Members');

        // Query: Charlie's teams
        buf.writeln('\n--- Traversal: Charlie\'s teams ---');
        await relManager
            .setRelated('graph_demo', 'charlie', 'teams', ['team1', 'team2']);
        final charlieTeams =
            await relManager.getRelated('graph_demo', 'charlie', 'teams');
        buf.writeln('  Charlie\'s teams: $charlieTeams');

        // DFS/BFS simulation using queries
        buf.writeln('\n--- Graph Queries via Relations ---');
        buf.writeln(
            '  Relations enable: one-to-one, one-to-many, many-to-many');
        buf.writeln('  LazyRelation loads data on demand');
        buf.writeln('  RelationIndex provides O(1) lookups');
        buf.writeln('  CascadeDelete removes orphans');

        // Cascade delete
        buf.writeln('\n--- Cascade Delete Simulation ---');
        relManager.createRelation(
            'graph_demo',
            RelationConfig(
              field: 'teamMembers',
              targetBox: 'graph_demo',
              targetField: 'teamId',
              type: RelationType.oneToMany,
              cascadeDelete: true,
            ));
        final cascade = relManager.cascadeDelete('graph_demo', 'team1');
        buf.writeln('  If team1 deleted, also delete: $cascade');

        await box.close();
        return buf.toString();
      },
    );
  }
}
