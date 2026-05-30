import 'dart:collection';

import 'package:rift/src/box/box.dart';

/// Simple graph data model for Rift.
/// Supports nodes, edges, and basic traversal queries.
///
/// The [GraphStore] stores graph data in two boxes:
/// - A **nodes box** for storing node data (label + properties)
/// - An **edges box** for storing edge data (from, to, label, properties)
///
/// Node keys are generated as `node_{uuid-like-id}` and edge keys as
/// `edge_{uuid-like-id}`. Both nodes and edges store their data as
/// maps with reserved fields for graph metadata.
///
/// Usage:
/// ```dart
/// final nodesBox = await Rift.openBox('graph_nodes');
/// final edgesBox = await Rift.openBox('graph_edges');
/// final graph = GraphStore(nodesBox, edgesBox);
///
/// final alice = await graph.addNode('person', {'name': 'Alice', 'age': 30});
/// final bob = await graph.addNode('person', {'name': 'Bob', 'age': 25});
/// final edge = await graph.addEdge(alice, bob, 'knows', properties: {'since': 2020});
///
/// final neighbors = graph.getNeighbors(alice);
/// final path = graph.shortestPath(alice, bob);
/// ```
class GraphStore {
  final Box _nodesBox;
  final Box _edgesBox;

  int _nodeCounter = 0;
  int _edgeCounter = 0;

  /// Create a [GraphStore] with the given [nodesBox] and [edgesBox].
  GraphStore(this._nodesBox, this._edgesBox);

  /// Add a node with a [label] and [properties].
  ///
  /// Returns the generated node ID (e.g., `node_0`, `node_1`, ...).
  Future<String> addNode(String label, Map<String, dynamic> properties) async {
    final nodeId = 'node_$_nodeCounter';
    _nodeCounter++;
    await _nodesBox.put(nodeId, {
      'id': nodeId,
      'label': label,
      'properties': Map<String, dynamic>.from(properties),
    });
    return nodeId;
  }

  /// Add an edge between [fromNodeId] and [toNodeId] with a [label].
  ///
  /// Optionally provide [properties] for the edge.
  /// Returns the generated edge ID (e.g., `edge_0`, `edge_1`, ...).
  Future<String> addEdge(
    String fromNodeId,
    String toNodeId,
    String label, {
    Map<String, dynamic>? properties,
  }) async {
    final edgeId = 'edge_$_edgeCounter';
    _edgeCounter++;
    await _edgesBox.put(edgeId, {
      'id': edgeId,
      'from': fromNodeId,
      'to': toNodeId,
      'label': label,
      'properties': properties != null
          ? Map<String, dynamic>.from(properties)
          : <String, dynamic>{},
    });
    return edgeId;
  }

  /// Get a node by its [nodeId].
  ///
  /// Returns the node data as a Map, or null if not found.
  Map<String, dynamic>? getNode(String nodeId) {
    final value = _nodesBox.get(nodeId);
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  /// Get an edge by its [edgeId].
  ///
  /// Returns the edge data as a Map, or null if not found.
  Map<String, dynamic>? getEdge(String edgeId) {
    final value = _edgesBox.get(edgeId);
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  /// Get all edges originating from [nodeId].
  ///
  /// If [label] is provided, only edges with that label are returned.
  List<Map<String, dynamic>> getOutgoingEdges(String nodeId, {String? label}) {
    final results = <Map<String, dynamic>>[];
    for (final key in _edgesBox.keys) {
      final value = _edgesBox.get(key);
      if (value is Map) {
        if (value['from'] == nodeId) {
          if (label == null || value['label'] == label) {
            results.add(Map<String, dynamic>.from(value));
          }
        }
      }
    }
    return results;
  }

  /// Get all edges pointing to [nodeId].
  ///
  /// If [label] is provided, only edges with that label are returned.
  List<Map<String, dynamic>> getIncomingEdges(String nodeId, {String? label}) {
    final results = <Map<String, dynamic>>[];
    for (final key in _edgesBox.keys) {
      final value = _edgesBox.get(key);
      if (value is Map) {
        if (value['to'] == nodeId) {
          if (label == null || value['label'] == label) {
            results.add(Map<String, dynamic>.from(value));
          }
        }
      }
    }
    return results;
  }

  /// Traverse the graph starting from [startNodeId].
  ///
  /// Follows edges according to [direction]:
  /// - [Direction.outgoing]: Follow edges from start node
  /// - [Direction.incoming]: Follow edges to start node
  /// - [Direction.both]: Follow edges in both directions
  ///
  /// [maxDepth] limits how many hops to traverse (default 3).
  /// [edgeLabel] filters which edges to follow (null = all edges).
  ///
  /// Returns all visited nodes (excluding the start node).
  List<Map<String, dynamic>> traverse(
    String startNodeId, {
    int maxDepth = 3,
    String? edgeLabel,
    Direction direction = Direction.outgoing,
  }) {
    final visited = <String>{startNodeId};
    final result = <Map<String, dynamic>>[];
    final queue = Queue<_TraversalNode>();
    queue.add(_TraversalNode(startNodeId, 0));

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (current.depth >= maxDepth) continue;

      // Get neighbor node IDs based on direction
      final neighborIds = _getNeighborIds(current.nodeId, direction, edgeLabel);

      for (final neighborId in neighborIds) {
        if (visited.contains(neighborId)) continue;
        visited.add(neighborId);

        final nodeData = getNode(neighborId);
        if (nodeData != null) {
          result.add(nodeData);
          queue.add(_TraversalNode(neighborId, current.depth + 1));
        }
      }
    }

    return result;
  }

  /// Find the shortest path between [fromNodeId] and [toNodeId].
  ///
  /// Uses BFS to find the shortest path in terms of number of edges.
  /// Returns a list of node IDs representing the path from [fromNodeId]
  /// to [toNodeId], or null if no path exists.
  List<String>? shortestPath(String fromNodeId, String toNodeId) {
    if (fromNodeId == toNodeId) return [fromNodeId];

    final visited = <String>{fromNodeId};
    final parent = <String, String>{};
    final queue = Queue<String>();
    queue.add(fromNodeId);

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();

      // Check both outgoing and incoming edges for undirected traversal
      final neighborIds = _getNeighborIds(current, Direction.both, null);

      for (final neighborId in neighborIds) {
        if (visited.contains(neighborId)) continue;
        visited.add(neighborId);
        parent[neighborId] = current;

        if (neighborId == toNodeId) {
          // Reconstruct path
          final path = <String>[];
          var node = toNodeId;
          while (node != fromNodeId) {
            path.add(node);
            node = parent[node]!;
          }
          path.add(fromNodeId);
          return path.reversed.toList();
        }

        queue.add(neighborId);
      }
    }

    return null; // No path found
  }

  /// Get all neighbors of [nodeId].
  ///
  /// Returns node data for all nodes connected to [nodeId] by an edge
  /// in either direction. If [edgeLabel] is provided, only edges with
  /// that label are considered.
  List<Map<String, dynamic>> getNeighbors(String nodeId, {String? edgeLabel}) {
    final neighborIds = <String>{};

    // Outgoing edges
    for (final key in _edgesBox.keys) {
      final value = _edgesBox.get(key);
      if (value is Map) {
        final matchesLabel = edgeLabel == null || value['label'] == edgeLabel;
        if (matchesLabel && value['from'] == nodeId && value['to'] is String) {
          neighborIds.add(value['to'] as String);
        }
        if (matchesLabel && value['to'] == nodeId && value['from'] is String) {
          neighborIds.add(value['from'] as String);
        }
      }
    }

    // Remove self
    neighborIds.remove(nodeId);

    return neighborIds
        .map((id) => getNode(id))
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  /// Remove a node and all edges connected to it.
  Future<void> removeNode(String nodeId) async {
    // Find and remove all edges connected to this node
    final edgeKeysToRemove = <dynamic>[];
    for (final key in _edgesBox.keys) {
      final value = _edgesBox.get(key);
      if (value is Map) {
        if (value['from'] == nodeId || value['to'] == nodeId) {
          edgeKeysToRemove.add(key);
        }
      }
    }

    await _edgesBox.deleteAll(edgeKeysToRemove);
    await _nodesBox.delete(nodeId);
  }

  /// Remove an edge by its [edgeId].
  Future<void> removeEdge(String edgeId) async {
    await _edgesBox.delete(edgeId);
  }

  /// Get all nodes with a specific [label].
  List<Map<String, dynamic>> getNodesByLabel(String label) {
    final results = <Map<String, dynamic>>[];
    for (final key in _nodesBox.keys) {
      final value = _nodesBox.get(key);
      if (value is Map && value['label'] == label) {
        results.add(Map<String, dynamic>.from(value));
      }
    }
    return results;
  }

  /// Get the total number of nodes in the graph.
  int get nodeCount => _nodesBox.length;

  /// Get the total number of edges in the graph.
  int get edgeCount => _edgesBox.length;

  /// Helper to get neighbor IDs based on direction.
  List<String> _getNeighborIds(
    String nodeId,
    Direction direction,
    String? edgeLabel,
  ) {
    final neighborIds = <String>[];

    for (final key in _edgesBox.keys) {
      final value = _edgesBox.get(key);
      if (value is! Map) continue;

      final matchesLabel = edgeLabel == null || value['label'] == edgeLabel;
      if (!matchesLabel) continue;

      if ((direction == Direction.outgoing || direction == Direction.both) &&
          value['from'] == nodeId &&
          value['to'] is String) {
        neighborIds.add(value['to'] as String);
      }

      if ((direction == Direction.incoming || direction == Direction.both) &&
          value['to'] == nodeId &&
          value['from'] is String) {
        neighborIds.add(value['from'] as String);
      }
    }

    return neighborIds;
  }
}

/// Direction for graph traversal.
enum Direction {
  /// Follow outgoing edges (from the start node).
  outgoing,

  /// Follow incoming edges (to the start node).
  incoming,

  /// Follow edges in both directions.
  both,
}

/// Internal helper for BFS traversal.
class _TraversalNode {
  final String nodeId;
  final int depth;

  _TraversalNode(this.nodeId, this.depth);
}
