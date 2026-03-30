import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../providers/task_providers.dart';
import '../widgets/task_card.dart';
import '../widgets/task_form_sheet.dart';

class KanbanColumn extends ConsumerWidget {
  const KanbanColumn({
    super.key,
    required this.status,
    required this.allTasks,
  });

  final TaskStatus status;
  final List<Task> allTasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredTasksProvider);
    final query = ref.watch(searchQueryProvider);

    final columnTasks = filteredAsync.when(
      loading: () => <Task>[],
      error: (_, __) => <Task>[],
      data: (list) => list.where((t) => t.status == status).toList(),
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F),
        border: Border(
          right: status != TaskStatus.done
              ? const BorderSide(color: Color(0x0FF5F0E8))
              : BorderSide.none,
        ),
      ),
      child: Column(
        children: [
          // ── Column header ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: _accentColor, width: 3),
                bottom: const BorderSide(color: Color(0x0FF5F0E8)),
              ),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.label.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        letterSpacing: 1.5,
                        color: Color(0xFF5A5660),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _subtitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF5F0E8),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x22C9A84C),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0x40C9A84C)),
                  ),
                  child: Text(
                    '${columnTasks.length}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFC9A84C),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Task list ─────────────────────────────────────────────────
          Expanded(
            child: columnTasks.isEmpty
                ? _EmptyState(status: status)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: columnTasks.length,
                    itemBuilder: (ctx, i) {
                      final task = columnTasks[i];
                      return TaskCard(
                        key: ValueKey(task.id),
                        task: task,
                        allTasks: allTasks,
                        searchQuery: query,
                        onTap: () => showTaskForm(ctx,
                            editTask: task, allTasks: allTasks),
                        onEdit: () => showTaskForm(ctx,
                            editTask: task, allTasks: allTasks),
                        onDelete: () => _confirmDelete(ctx, ref, task),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color get _accentColor => switch (status) {
        TaskStatus.todo => const Color(0xFFC9A84C),
        TaskStatus.inProgress => const Color(0xFF8B7BC8),
        TaskStatus.done => const Color(0xFF4ECDC4),
      };

  String get _subtitle => switch (status) {
        TaskStatus.todo => 'Awaiting Action',
        TaskStatus.inProgress => 'Currently Active',
        TaskStatus.done => 'Delivered & Closed',
      };

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Task',
            style: TextStyle(color: Color(0xFFF5F0E8))),
        content: Text(
          'Delete "${task.title}"?\nThis cannot be undone.',
          style: const TextStyle(color: Color(0xFF8A8490)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF8A8490))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFFF6B6B))),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(tasksProvider.notifier).deleteTask(task.id);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.status});
  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 1,
            color: const Color(0x40C9A84C),
          ),
          const SizedBox(height: 12),
          Text(
            'No entries',
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              color: Color(0xFF3A3640),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 32,
            height: 1,
            color: const Color(0x40C9A84C),
          ),
        ],
      ),
    );
  }
}
