import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.allTasks,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.searchQuery = '',
  });

  final Task task;
  final List<Task> allTasks;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String searchQuery;

  bool get _isActivelyBlocked {
    if (!task.isBlocked) return false;
    final blocker = allTasks.where((t) => t.id == task.blockedBy).firstOrNull;
    return blocker == null || blocker.status != TaskStatus.done;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBlocked = _isActivelyBlocked;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Stack(
          children: [
            // ── Card body ──────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFF1C1C28),
                border: Border(
                  left: BorderSide(
                    color: isBlocked
                        ? const Color(0xFF7C3AED)
                        : const Color(0xFFC9A84C),
                    width: 3,
                  ),
                  top: const BorderSide(color: Color(0x0FF5F0E8)),
                  right: const BorderSide(color: Color(0x0FF5F0E8)),
                  bottom: const BorderSide(color: Color(0x0FF5F0E8)),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x28000000),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Card content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: status pill + actions
                          Row(
                            children: [
                              _StatusPill(status: task.status),
                              const Spacer(),
                              if (onEdit != null)
                                _ActionBtn(
                                  icon: Icons.edit_outlined,
                                  onTap: onEdit!,
                                  tooltip: 'Edit',
                                ),
                              const SizedBox(width: 6),
                              if (onDelete != null)
                                _ActionBtn(
                                  icon: Icons.delete_outline_rounded,
                                  onTap: onDelete!,
                                  tooltip: 'Delete',
                                  danger: true,
                                ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Title with optional search highlight
                          _HighlightedText(
                            text: task.title,
                            query: searchQuery,
                            style: theme.textTheme.titleMedium!.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: isBlocked
                                  ? const Color(0xFF8A8490)
                                  : const Color(0xFFF5F0E8),
                            ),
                            maxLines: 2,
                          ),

                          if (task.description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _HighlightedText(
                              text: task.description,
                              query: searchQuery,
                              style: theme.textTheme.bodyMedium!.copyWith(
                                fontSize: 13,
                                height: 1.5,
                                color: const Color(0xFF5A5660),
                              ),
                              maxLines: 2,
                            ),
                          ],

                          const SizedBox(height: 14),

                          // Footer row
                          Row(
                            children: [
                              // Due date
                              if (task.dueDate != null)
                                _DueBadge(dueDate: task.dueDate!, status: task.status),

                              if (task.dueDate != null && task.isBlocked)
                                const SizedBox(width: 8),

                              // Blocked badge
                              if (task.isBlocked)
                                _BlockedBadge(
                                  blockedBy: task.blockedBy!,
                                  isActive: isBlocked,
                                ),

                              const Spacer(),

                              // Task ID
                              Text(
                                '#${task.id}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF3A3640),
                                  fontFamily: 'monospace',
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Frosted-glass overlay for actively blocked tasks
                    if (isBlocked)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0x55FFFFFF),
                                    const Color(0x33F5F3FF),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Blocked badge overlay (top-right corner) ───────────────
            if (isBlocked)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xCC1C1C28),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFF7C3AED),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded,
                          size: 11, color: Color(0xFFA78BFA)),
                      SizedBox(width: 5),
                      Text(
                        'Blocked',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFA78BFA),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Status pill ───────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      TaskStatus.todo => (
          const Color(0x22C9A84C),
          const Color(0xFFC9A84C),
        ),
      TaskStatus.inProgress => (
          const Color(0x228B7BC8),
          const Color(0xFFB8A9E8),
        ),
      TaskStatus.done => (
          const Color(0x224ECDC4),
          const Color(0xFF4ECDC4),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.danger = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2435),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0x1AF5F0E8)),
          ),
          child: Icon(
            icon,
            size: 14,
            color: danger
                ? const Color(0xFFFF6B6B)
                : const Color(0xFF8A8490),
          ),
        ),
      ),
    );
  }
}

// ── Due date badge ────────────────────────────────────────────────────────────

class _DueBadge extends StatelessWidget {
  const _DueBadge({required this.dueDate, required this.status});
  final DateTime dueDate;
  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final isOverdue = dueDate.isBefore(DateTime.now()) && status != TaskStatus.done;
    final color = isOverdue ? const Color(0xFFFF6B6B) : const Color(0xFF5A5660);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isOverdue ? Icons.warning_amber_rounded : Icons.schedule_rounded,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          DateFormat('MMM d').format(dueDate),
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ── Blocked-by badge ──────────────────────────────────────────────────────────

class _BlockedBadge extends StatelessWidget {
  const _BlockedBadge({required this.blockedBy, required this.isActive});
  final int blockedBy;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isActive ? Icons.lock_rounded : Icons.lock_open_rounded,
          size: 12,
          color: isActive
              ? const Color(0xFF7C3AED)
              : const Color(0xFF4ECDC4),
        ),
        const SizedBox(width: 4),
        Text(
          'blocked by #$blockedBy',
          style: TextStyle(
            fontSize: 11,
            color: isActive
                ? const Color(0xFF7C3AED)
                : const Color(0xFF4ECDC4),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Search highlight text ─────────────────────────────────────────────────────

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.query,
    required this.style,
    this.maxLines,
  });

  final String text;
  final String query;
  final TextStyle style;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text, style: style, maxLines: maxLines,
          overflow: maxLines != null ? TextOverflow.ellipsis : null);
    }

    final lower = text.toLowerCase();
    final lowerQ = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final idx = lower.indexOf(lowerQ, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) spans.add(TextSpan(text: text.substring(start, idx)));
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: style.copyWith(
          backgroundColor: const Color(0x44C9A84C),
          color: const Color(0xFFE8C97A),
        ),
      ));
      start = idx + query.length;
    }

    return RichText(
      text: TextSpan(style: style, children: spans),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
    );
  }
}
