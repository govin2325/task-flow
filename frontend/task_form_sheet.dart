import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/draft_task_controller.dart';
import '../models/task.dart';
import '../providers/task_providers.dart';
import '../widgets/progressive_button.dart';

/// Shows the create/edit bottom sheet and returns when done.
Future<void> showTaskForm(
  BuildContext context, {
  Task? editTask,
  List<Task> allTasks = const [],
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => TaskFormSheet(editTask: editTask, allTasks: allTasks),
  );
}

class TaskFormSheet extends ConsumerStatefulWidget {
  const TaskFormSheet({super.key, this.editTask, this.allTasks = const []});

  final Task? editTask;
  final List<Task> allTasks;

  @override
  ConsumerState<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends ConsumerState<TaskFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late DraftTaskController _draft;

  DateTime? _dueDate;
  TaskStatus _status = TaskStatus.todo;
  int? _blockedBy;
  bool _loading = false;

  bool get _isEdit => widget.editTask != null;

  @override
  void initState() {
    super.initState();
    _draft = DraftTaskController(draftId: _isEdit ? 'edit_${widget.editTask!.id}' : 'new');

    if (_isEdit) {
      final t = widget.editTask!;
      _draft.titleController.text = t.title;
      _draft.descriptionController.text = t.description;
      _dueDate = t.dueDate;
      _status = t.status;
      _blockedBy = t.blockedBy;
    } else {
      _draft.init(); // loads saved draft
    }
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<Task> get _blockerCandidates =>
      widget.allTasks.where((t) => t.id != widget.editTask?.id).toList();

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: const Color(0xFFC9A84C),
                onPrimary: const Color(0xFF0A0A0F),
                surface: const Color(0xFF1C1C28),
              ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;

    final pickedTime = await showTimePicker(
      // ignore: use_build_context_synchronously
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate ?? now),
    );

    setState(() {
      _dueDate = pickedTime == null
          ? picked
          : DateTime(picked.year, picked.month, picked.day,
              pickedTime.hour, pickedTime.minute);
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    try {
      final notifier = ref.read(tasksProvider.notifier);

      if (_isEdit) {
        final updated = widget.editTask!.copyWith(
          title: _draft.titleController.text.trim(),
          description: _draft.descriptionController.text.trim(),
          dueDate: _dueDate,
          clearDueDate: _dueDate == null,
          status: _status,
          blockedBy: _blockedBy,
          clearBlockedBy: _blockedBy == null,
        );
        await notifier.updateTask(updated);
      } else {
        const tempId = 0;
        final task = Task(
          id: tempId,
          title: _draft.titleController.text.trim(),
          description: _draft.descriptionController.text.trim(),
          dueDate: _dueDate,
          status: _status,
          blockedBy: _blockedBy,
        );
        await notifier.createTask(task);
        await _draft.clear();
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF6B6B),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF12121A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Color(0x22C9A84C), width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Handle ────────────────────────────────────────────────
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2435),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // ── Header ────────────────────────────────────────────────
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEdit ? 'Editing Entry' : 'New Entry',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          letterSpacing: 1.5,
                          color: Color(0xFFC9A84C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isEdit ? 'Edit Task' : 'Create Task',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF5F0E8),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF5A5660)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _goldDivider(),
              const SizedBox(height: 20),

              // ── Title ─────────────────────────────────────────────────
              _label('Title', required: true),
              const SizedBox(height: 8),
              TextFormField(
                controller: _draft.titleController,
                maxLength: 160,
                style: const TextStyle(color: Color(0xFFF5F0E8)),
                decoration: const InputDecoration(
                  hintText: 'What needs to be accomplished?',
                  counterText: '',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 16),

              // ── Description ───────────────────────────────────────────
              _label('Description'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _draft.descriptionController,
                maxLines: 3,
                maxLength: 5000,
                style: const TextStyle(color: Color(0xFFF5F0E8)),
                decoration: const InputDecoration(
                  hintText: 'Provide context, objectives, or acceptance criteria…',
                  counterText: '',
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 20),
              _goldDivider(),
              const SizedBox(height: 20),

              // ── Due Date + Status (side by side) ──────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Due Date'),
                        const SizedBox(height: 8),
                        _DatePickerTile(
                          value: _dueDate,
                          onTap: _pickDate,
                          onClear: () => setState(() => _dueDate = null),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Status'),
                        const SizedBox(height: 8),
                        _StatusDropdown(
                          value: _status,
                          onChanged: (v) => setState(() => _status = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Blocked By ────────────────────────────────────────────
              _label('Blocked By'),
              const SizedBox(height: 8),
              _BlockedByDropdown(
                candidates: _blockerCandidates,
                value: _blockedBy,
                onChanged: (v) => setState(() => _blockedBy = v),
              ),

              const SizedBox(height: 28),

              // ── Footer ────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8A8490),
                        side: const BorderSide(color: Color(0x1AF5F0E8)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Discard'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ProgressiveButton(
                      label: _isEdit ? 'Save Changes' : 'Save Task',
                      loading: _loading,
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text, {bool required = false}) {
    return Row(
      children: [
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            letterSpacing: 1.5,
            color: Color(0xFF8A8490),
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(color: Color(0xFFC9A84C), fontSize: 10),
          ),
      ],
    );
  }

  Widget _goldDivider() => Container(
        height: 1,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, Color(0x40C9A84C), Colors.transparent],
          ),
        ),
      );
}

// ── Date picker tile ──────────────────────────────────────────────────────────

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C28),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x0FF5F0E8)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 14, color: Color(0xFF8A8490)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value != null
                    ? '${value!.day} ${_month(value!.month)} ${value!.year}'
                    : 'Pick date',
                style: TextStyle(
                  fontSize: 13,
                  color: value != null
                      ? const Color(0xFFF5F0E8)
                      : const Color(0xFF5A5660),
                ),
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded,
                    size: 14, color: Color(0xFF5A5660)),
              ),
          ],
        ),
      ),
    );
  }

  String _month(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}

// ── Status dropdown ───────────────────────────────────────────────────────────

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({required this.value, required this.onChanged});

  final TaskStatus value;
  final ValueChanged<TaskStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C28),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x0FF5F0E8)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TaskStatus>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF1C1C28),
          style: const TextStyle(color: Color(0xFFF5F0E8), fontSize: 13),
          items: TaskStatus.values.map((s) {
            return DropdownMenuItem(
              value: s,
              child: Text('${s.emoji} ${s.label}'),
            );
          }).toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
      ),
    );
  }
}

// ── Blocked-by dropdown ───────────────────────────────────────────────────────

class _BlockedByDropdown extends StatelessWidget {
  const _BlockedByDropdown({
    required this.candidates,
    required this.value,
    required this.onChanged,
  });

  final List<Task> candidates;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C28),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x0FF5F0E8)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF1C1C28),
          style: const TextStyle(color: Color(0xFFF5F0E8), fontSize: 13),
          hint: const Text(
            '— None (unblocked) —',
            style: TextStyle(color: Color(0xFF5A5660), fontSize: 13),
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('— None (unblocked) —',
                  style: TextStyle(color: Color(0xFF5A5660))),
            ),
            ...candidates.map((t) => DropdownMenuItem<int?>(
                  value: t.id,
                  child: Text(
                    '#${t.id} — ${t.title.length > 40 ? '${t.title.substring(0, 40)}…' : t.title}  [${t.status.label}]',
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
