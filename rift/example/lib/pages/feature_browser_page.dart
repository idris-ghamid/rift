import 'package:flutter/material.dart';
import '../home_page.dart';
import '../widgets/feature_card.dart';
import '../widgets/empty_states.dart';
import '../systems/layout_engine.dart';

/// Feature browser page with grid/list views
class FeatureBrowserPage extends StatefulWidget {
  final FeatureCategory? initialCategory;

  const FeatureBrowserPage({
    super.key,
    this.initialCategory,
  });

  @override
  State<FeatureBrowserPage> createState() => _FeatureBrowserPageState();
}

class _FeatureBrowserPageState extends State<FeatureBrowserPage> {
  FeatureCategory? _selectedCategory;
  String _searchQuery = '';
  bool _isGridView = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FeatureInfo> get _filteredFeatures {
    var features = allFeatures;

    if (_selectedCategory != null) {
      features =
          features.where((f) => f.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      features = features.where((f) {
        return f.name.toLowerCase().contains(q) ||
            f.description.toLowerCase().contains(q);
      }).toList();
    }

    return features;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredFeatures;
    final width = MediaQuery.of(context).size.width;
    final columnCount = LayoutEngine.getColumnCount(width);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(
          _selectedCategory?.label ?? 'All Features',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
            letterSpacing: -0.3,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          // Toggle view button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withAlpha(12)
                  : Colors.black.withAlpha(6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                color: isDark ? Colors.white70 : Colors.black54,
                size: 22,
              ),
              onPressed: () => setState(() => _isGridView = !_isGridView),
              tooltip: _isGridView ? 'List View' : 'Grid View',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withAlpha(51)
                        : Colors.black.withAlpha(13),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Search features...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white24 : Colors.black26,
                    fontSize: 16,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: isDark ? Colors.white24 : Colors.black26,
                    size: 22,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // Category filter chips
          if (_selectedCategory == null)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: FeatureCategory.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = FeatureCategory.values[index];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            cat.color.withAlpha(26),
                            cat.color.withAlpha(15)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: cat.color.withAlpha(51),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.icon, size: 16, color: cat.color),
                          const SizedBox(width: 6),
                          Text(
                            cat.label.split(' ')[0],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: cat.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 12),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${filtered.length} features',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_selectedCategory != null || _searchQuery.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = null;
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Clear All',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF007AFF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Features grid/list
          Expanded(
            child: filtered.isEmpty
                ? NoSearchResults(
                    query: _searchQuery,
                    onClear: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                        _selectedCategory = null;
                      });
                    },
                  )
                : _isGridView
                    ? _buildGridView(filtered, columnCount, isDark)
                    : _buildListView(filtered, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(
      List<FeatureInfo> features, int columnCount, bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        return FeatureCard(
          feature: features[index],
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: features[index].builder),
            );
          },
        );
      },
    );
  }

  Widget _buildListView(List<FeatureInfo> features, bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: features.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final feature = features[index];
        final catColor = feature.category.color;

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: feature.builder),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withAlpha(51)
                      : Colors.black.withAlpha(13),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [catColor.withAlpha(26), catColor.withAlpha(15)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    feature.icon,
                    size: 26,
                    color: catColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? Colors.white : const Color(0xFF1C1C1E),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        feature.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.black54,
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              catColor.withAlpha(26),
                              catColor.withAlpha(15)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: catColor.withAlpha(38)),
                        ),
                        child: Text(
                          feature.category.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: catColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
