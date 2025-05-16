// recent_search_keywords.dart

import 'package:flutter/material.dart';

class RecentSearchKeywords extends StatelessWidget {
  final List<String> keywords;
  final void Function(String keyword) onKeywordTap;

  const RecentSearchKeywords({
    super.key,
    required this.keywords,
    required this.onKeywordTap,
  });

  @override
  Widget build(BuildContext context) {
    if (keywords.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text("최근 검색어", style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: keywords.map((word) {
            return ActionChip(
              label: Text(word),
              onPressed: () => onKeywordTap(word),
            );
          }).toList(),
        ),
      ],
    );
  }
}
