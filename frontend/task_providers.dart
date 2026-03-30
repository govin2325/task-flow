import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../services/task_api_service.dart';
import '../services/websocket_service.dart';

// ── Config ──────────────────────────────────────────────────────────────────

/// Change to your machine's IP if running on a real device.
/// Android emulator: 10.0.2.2  |  iOS simulator / desktop: 127.0.0.1
const _kBaseUrl = 'http://10.0.2.2:8000';
const _kWsUrl = 'ws://10.0.2.2:8000/ws';

// ── Dio ──────────────────────────────────────────────────────────────────────

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: _kBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );
});

// ── API service ──────────────────────────────────────────────────────────────

final taskApiServiceProvider = Provider<TaskApiService>((ref) {
  return TaskApiService(ref.watch(dioProvider));
});

// ── WebSocket service ────────────────────────────────────────────────────────

final wsServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService(_kWsUrl);
  service.connect();
  ref.onDispose(service.dispose);
  return service;
});

// ── Connected-user count ─────────────────────────────────────────────────────

final connectedCountProvider = StreamProvider<int>((ref) {
  final ws = ref.watch(wsServiceProvider);
  return ws.events
      .where((e) => e.type == WsEventType.connectedCount)
      .map((e) {
    final data = e.data;
    if (data is Map) return (data['count'] as num?)?.toInt() ?? 1;
    return 1;
  });
});

// ── Tasks ─────────────────────────────────────────────────────────────────────

final tasksProvider =
    AsyncNotifierProvider<TasksNotifier, List<Task>>(TasksNotifier.new);

class TasksNotifier extends AsyncNotifier<List<Task>> {
  late TaskApiService _service;

  @override
  Future<List<Task>> build() async {
    _service = ref.read(taskApiServiceProvider);

    // Subscribe to WebSocket events and mutate local state immediately
    ref.listen(wsServiceProvider, (_, ws) {
      ws.events.listen(_handleWsEvent);
    });
    // Also listen right now
    ref.read(wsServiceProvider).events.listen(_handleWsEvent);

    return _service.fetchTasks();
  }

  void _handleWsEvent(WsEvent event) {
    final current = state.valueOrNull;
    if (current == null) return;

    switch (event.type) {
      case WsEventType.taskCreated:
        final task = Task.fromJson(event.data as Map<String, dynamic>);
        if (!current.any((t) => t.id == task.id)) {
          state = AsyncData([...current, task]);
        }

      case WsEventType.taskUpdated:
        final task = Task.fromJson(event.data as Map<String, dynamic>);
        state = AsyncData(
          current.map((t) => t.id == task.id ? task : t).toList(),
        );

      case WsEventType.taskDeleted:
        final id = (event.data as Map<String, dynamic>)['id'] as int;
        state = AsyncData(current.where((t) => t.id != id).toList());

      default:
        break;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_service.fetchTasks);
  }

  Future<void> createTask(Task task) async {
    await _service.createTask(task);
    // WS event will update state; fallback refresh after short delay
    Future.delayed(const Duration(seconds: 1), () {
      if (state.valueOrNull?.any((t) => t.title == task.title) == false) {
        refresh();
      }
    });
  }

  Future<void> updateTask(Task task) async {
    await _service.updateTask(task);
  }

  Future<void> deleteTask(int id) async {
    await _service.deleteTask(id);
  }
}

// ── Search + filter ───────────────────────────────────────────────────────────

enum StatusFilter { all, todo, inProgress, done, blocked }

final searchQueryProvider = StateProvider<String>((ref) => '');
final statusFilterProvider = StateProvider<StatusFilter>((ref) => StatusFilter.all);

final filteredTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final tasksAsync = ref.watch(tasksProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  final statusFilter = ref.watch(statusFilterProvider);

  return tasksAsync.whenData((tasks) {
    var list = tasks;

    // Status / blocked filter
    switch (statusFilter) {
      case StatusFilter.todo:
        list = list.where((t) => t.status == TaskStatus.todo).toList();
      case StatusFilter.inProgress:
        list = list.where((t) => t.status == TaskStatus.inProgress).toList();
      case StatusFilter.done:
        list = list.where((t) => t.status == TaskStatus.done).toList();
      case StatusFilter.blocked:
        list = list.where((t) {
          if (!t.isBlocked) return false;
          final blocker = tasks.firstWhere(
            (b) => b.id == t.blockedBy,
            orElse: () => t,
          );
          return blocker.status != TaskStatus.done;
        }).toList();
      case StatusFilter.all:
        break;
    }

    // Text search
    if (query.isNotEmpty) {
      list = list
          .where((t) =>
              t.title.toLowerCase().contains(query) ||
              t.description.toLowerCase().contains(query))
          .toList();
    }

    return list;
  });
});
