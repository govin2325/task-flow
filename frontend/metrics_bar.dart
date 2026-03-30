import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../providers/task_providers.dart';

class MetricsBar extends ConsumerWidget {
  const MetricsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final connectedAsync = ref.watch(connectedCountProvider);

    return tasksAsync.when(
      loading: () => const SizedBox(height: 52),
      error: (_, __) => const SizedBox(height: 52),
      data: (tasks) {
        final todo = tasks.where((t) => t.status == TaskStatus.todo).length;
        final prog = tasks.where((t) => t.status == TaskStatus.inProgress).length;
        final done = tasks.where((t) => t.status == TaskStatus.done).length;
        final blocked = tasks.where((t) {
          if (!t.isBlocked) return false;
          final b = tasks.firstWhere((b) => b.id == t.blockedBy,
              orElse: () => t);
          return b.status != TaskStatus.done;
        }).length;

        return Container(
          height: 52,
          decoration: const BoxDecoration(
            color: Color(0x990A0A0F),
            border: Border(
              bottom: BorderSide(color: Color(0x0FF5F0E8)),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _Metric(label: 'Total', value: '${tasks.length}',
                    color: const Color(0xFFC9A84C)),
                _divider(),
                _Metric(label: 'Backlog', value: '$todo'),
                _divider(),
                _Metric(label: 'Active', value: '$prog',
                    color: const Color(0xFFB8A9E8)),
                _divider(),
                _Metric(label: 'Done', value: '$done',
                    color: const Color(0xFF4ECDC4)),
                if (blocked > 0) ...[
                  _divider(),
                  _Metric(label: 'Blocked', value: '$blocked',
                      color: const Color(0xFFFF6B6B)),
                ],
                _divider(),
                connectedAsync.when(
                  loading: () => _Metric(label: 'Online', value: '…'),
                  error: (_, __) => _Metric(label: 'Online', value: '?'),
                  data: (n) => _Metric(
                    label: 'Online',
                    value: '$n',
                    color: const Color(0xFF4ECDC4),
                    icon: Icons.circle,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 28,
        color: const Color(0x0FF5F0E8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.color,
    this.icon,
  });

  final String label;
  final String value;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              letterSpacing: 1.2,
              color: Color(0xFF3A3640),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 8, color: color ?? const Color(0xFF8A8490)),
                const SizedBox(width: 4),
              ],
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color ?? const Color(0xFFF5F0E8),
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
