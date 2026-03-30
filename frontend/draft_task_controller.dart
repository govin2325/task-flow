import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists new-task form fields to SharedPreferences with 250 ms debounce.
/// For edit mode pass a non-null [draftId] — or use a fixed key like "new".
class DraftTaskController {
  DraftTaskController({required this.draftId});

  final String draftId;

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  SharedPreferences? _prefs;
  Timer? _debounce;

  String get _titleKey => 'task_draft_${draftId}_title';
  String get _descKey => 'task_draft_${draftId}_desc';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    titleController.text = _prefs?.getString(_titleKey) ?? '';
    descriptionController.text = _prefs?.getString(_descKey) ?? '';
    titleController.addListener(_persist);
    descriptionController.addListener(_persist);
  }

  void _persist() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      await _prefs?.setString(_titleKey, titleController.text);
      await _prefs?.setString(_descKey, descriptionController.text);
    });
  }

  Future<void> clear() async {
    await _prefs?.remove(_titleKey);
    await _prefs?.remove(_descKey);
    titleController.clear();
    descriptionController.clear();
  }

  void dispose() {
    _debounce?.cancel();
    titleController.removeListener(_persist);
    descriptionController.removeListener(_persist);
    titleController.dispose();
    descriptionController.dispose();
  }
}
