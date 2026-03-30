import 'dart:collection';

import 'package:dio/dio.dart';

import '../models/task.dart';

class TaskApiService {
  TaskApiService(this._dio);

  final Dio _dio;
  final Set<String> _inFlightKeys = HashSet<String>();

  Future<T> _runLocked<T>({
    required String key,
    required Future<T> Function() action,
  }) async {
    if (_inFlightKeys.contains(key)) {
      throw StateError('Action "$key" is already in progress.');
    }
    _inFlightKeys.add(key);
    try {
      return await action();
    } finally {
      _inFlightKeys.remove(key);
    }
  }

  Future<List<Task>> fetchTasks() async {
    final response = await _dio.get<List<dynamic>>('/tasks');
    return (response.data ?? [])
        .map((item) => Task.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Task> createTask(Task task) {
    return _runLocked(
      key: 'create:${task.title}',
      action: () async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/tasks',
          data: task.toUpsertJson(),
        );
        return Task.fromJson(response.data!);
      },
    );
  }

  Future<Task> updateTask(Task task) {
    return _runLocked(
      key: 'update:${task.id}',
      action: () async {
        final response = await _dio.patch<Map<String, dynamic>>(
          '/tasks/${task.id}',
          data: task.toUpsertJson(),
        );
        return Task.fromJson(response.data!);
      },
    );
  }

  Future<void> deleteTask(int id) {
    return _runLocked(
      key: 'delete:$id',
      action: () async {
        await _dio.delete('/tasks/$id');
      },
    );
  }
}
