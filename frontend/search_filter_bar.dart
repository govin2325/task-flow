import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/task_providers.dart';

class SearchFilterBar extends ConsumerStatefulWidget {
  const SearchFilterBar({super.key});

  @override
  ConsumerState<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends ConsumerState<SearchFilterBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeFilter = ref.watch(statusFilterProvider);

    return Container(
      color: const Color(0x880A0A0F),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        children: [
          // ── Search input ──────────────────────────────────────────────
          SizedBox(
            height: 40,
            child: TextField(
              controller: _controller,
              onChanged: (v) =>
                  ref.read(searchQueryProvider.notifier).state = v,
              style: const TextStyle(
                  color: Color(0xFFF5F0E8), fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search tasks…',
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 18, color: Color(0xFF5A5660)),
                suffixIcon: _controller.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _controller.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: Color(0xFF5A5660)),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ── Filter pills ──────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: StatusFilter.values.map((f) {
                final isActive = activeFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () =>
                        ref.read(statusFilterProvider.notifier).state = f,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0x22C9A84C)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFFC9A84C)
                              : const Color(0x1AF5F0E8),
                        ),
                      ),
                      child: Text(
                        _filterLabel(f),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          letterSpacing: 0.8,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isActive
                              ? const Color(0xFFC9A84C)
                              : const Color(0xFF5A5660),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _filterLabel(StatusFilter f) => switch (f) {
        StatusFilter.all => 'All',
        StatusFilter.todo => 'Backlog',
        StatusFilter.inProgress => 'In Progress',
        StatusFilter.done => 'Done',
        StatusFilter.blocked => 'Blocked',
      };
}
