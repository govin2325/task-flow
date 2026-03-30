import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../providers/task_providers.dart';
import '../widgets/kanban_column.dart';
import '../widgets/metrics_bar.dart';
import '../widgets/search_filter_bar.dart';
import '../widgets/task_form_sheet.dart';

class TaskBoardScreen extends ConsumerStatefulWidget {
  const TaskBoardScreen({super.key});

  @override
  ConsumerState<TaskBoardScreen> createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends ConsumerState<TaskBoardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);
    final isWide = MediaQuery.of(context).size.width >= 900;

    final allTasks = tasksAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: _buildAppBar(context, allTasks),
      body: Column(
        children: [
          const MetricsBar(),
          const SearchFilterBar(),
          Expanded(
            child: tasksAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFC9A84C),
                ),
              ),
              error: (e, _) => _ErrorView(
                message: e.toString(),
                onRetry: () => ref.read(tasksProvider.notifier).refresh(),
              ),
              data: (_) => isWide
                  ? _KanbanDesktop(allTasks: allTasks)
                  : _KanbanMobile(
                      allTasks: allTasks,
                      tabController: _tabController,
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTaskForm(context, allTasks: allTasks),
        backgroundColor: const Color(0xFFC9A84C),
        foregroundColor: const Color(0xFF0A0A0F),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Task',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, List<Task> allTasks) {
    final wsState = ref.watch(connectedCountProvider);
    final isConnected = wsState.valueOrNull != null;
    final isWide = MediaQuery.of(context).size.width >= 900;

    return AppBar(
      backgroundColor: const Color(0xEC0A0A0F),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0x0FF5F0E8)),
          ),
        ),
        foregroundDecoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0x00000000), Color(0x00000000)],
          ),
        ),
      ),
      title: Row(
        children: [
          // Gold accent bar
          Container(
            width: 3,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(
                colors: [Color(0xFFC9A84C), Color(0xFFE8C97A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          const SizedBox(width: 12),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Color(0xFFF5F0E8),
              ),
              children: [
                TextSpan(text: 'Task'),
                TextSpan(
                  text: 'Flow',
                  style: TextStyle(
                    color: Color(0xFFC9A84C),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0x1AF5F0E8)),
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Text(
              'OBSIDIAN GOLD',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                letterSpacing: 1.5,
                color: Color(0xFF3A3640),
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Live indicator
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected
                      ? const Color(0xFF4ECDC4)
                      : const Color(0xFFFF6B6B),
                  boxShadow: isConnected
                      ? [
                          const BoxShadow(
                            color: Color(0x664ECDC4),
                            blurRadius: 8,
                          )
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isConnected ? 'Live' : 'Offline',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  letterSpacing: 0.8,
                  color: isConnected
                      ? const Color(0xFF4ECDC4)
                      : const Color(0xFFFF6B6B),
                ),
              ),
            ],
          ),
        ),

        // Refresh
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 20),
          color: const Color(0xFF5A5660),
          tooltip: 'Refresh tasks',
          onPressed: () => ref.read(tasksProvider.notifier).refresh(),
        ),

        if (!isWide) ...[
          // Mobile tab labels in appbar bottom
        ],
        const SizedBox(width: 8),
      ],
      bottom: isWide
          ? null
          : TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFC9A84C),
              indicatorWeight: 2,
              labelColor: const Color(0xFFC9A84C),
              unselectedLabelColor: const Color(0xFF5A5660),
              labelStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
              tabs: TaskStatus.values
                  .map((s) => Tab(text: s.label.toUpperCase()))
                  .toList(),
            ),
    );
  }
}

// ── Desktop: 3-column kanban ──────────────────────────────────────────────────

class _KanbanDesktop extends StatelessWidget {
  const _KanbanDesktop({required this.allTasks});
  final List<Task> allTasks;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: TaskStatus.values
          .map((s) => Expanded(
                child: KanbanColumn(status: s, allTasks: allTasks),
              ))
          .toList(),
    );
  }
}

// ── Mobile: tabbed single-column ──────────────────────────────────────────────

class _KanbanMobile extends StatelessWidget {
  const _KanbanMobile({
    required this.allTasks,
    required this.tabController,
  });
  final List<Task> allTasks;
  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: tabController,
      children: TaskStatus.values
          .map((s) => KanbanColumn(status: s, allTasks: allTasks))
          .toList(),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: Color(0xFF3A3640)),
            const SizedBox(height: 16),
            const Text(
              'Unable to reach server',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF5F0E8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF5A5660),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
