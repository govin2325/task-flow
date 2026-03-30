# TaskFlow — Full Stack Task Manager

A real-time Kanban board with a **FastAPI + SQLite** backend and a **Flutter** frontend.

**Track A: The Full-Stack Builder (Expected time: 6-8 hours)**
- Frontend: Flutter & Dart
- Backend: Python (FastAPI)
- Database: SQLite
- Requirement: Connect the Flutter app to the Python REST API

I have followed Track A.

```
taskflow/
├── backend/                  ← FastAPI (Python)
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py           ← FastAPI app + WebSocket endpoint
│   │   ├── database.py       ← SQLAlchemy + SQLite setup
│   │   ├── models.py         ← Task ORM model
│   │   ├── schemas.py        ← Pydantic request/response schemas
│   │   ├── ws_manager.py     ← WebSocket connection manager
│   │   └── routers/
│   │       └── tasks.py      ← CRUD endpoints
│   ├── requirements.txt
│   └── README.md
│
└── frontend/                 ← Flutter app
    └── lib/
        ├── main.dart          ← App entry + dark theme
        ├── models/
        │   └── task.dart      ← Task data class + status enum
        ├── services/
        │   ├── task_api_service.dart   ← Dio REST client
        │   └── websocket_service.dart  ← WebSocket + auto-reconnect
        ├── controllers/
        │   └── draft_task_controller.dart  ← SharedPreferences draft save
        ├── providers/
        │   └── task_providers.dart    ← Riverpod state (tasks, search, filter)
        ├── screens/
        │   └── task_board_screen.dart ← Main screen (desktop/mobile layout)
        └── widgets/
            ├── kanban_column.dart     ← Single Kanban column
            ├── task_card.dart         ← Task card with frosted-glass blocked state
            ├── task_form_sheet.dart   ← Create/edit bottom sheet
            ├── search_filter_bar.dart ← Search input + status filter pills
            ├── metrics_bar.dart       ← Stats strip (total, active, done, etc.)
            └── progressive_button.dart ← Animated loading submit button
```

---

## 1 — Start the Backend

```bash
cd taskflow/backend

python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate

pip install -r requirements.txt

uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

> API: http://localhost:8000  
> Swagger docs: http://localhost:8000/docs  
> WebSocket: ws://localhost:8000/ws

---

## 2 — Run the Flutter App

```bash
cd taskflow/frontend

flutter pub get

# Android emulator (default — uses 10.0.2.2 to reach host)
flutter run

# iOS simulator or desktop
# Edit lib/providers/task_providers.dart:
#   const _kBaseUrl = 'http://127.0.0.1:8000';
#   const _kWsUrl   = 'ws://127.0.0.1:8000/ws';
flutter run
```

---

## Features

| Feature | Detail |
|---------|--------|
| **Full CRUD** | Create, read, update, delete tasks |
| **Kanban board** | 3 columns: Backlog / In Progress / Done |
| **Real-time sync** | WebSocket broadcasts to all connected clients |
| **Search** | Debounced title + description search with gold highlight |
| **Filter pills** | All / Backlog / In Progress / Done / Blocked |
| **Draft persistence** | New-task form auto-saved to SharedPreferences |
| **Blocked tasks** | Frosted-glass + purple tint when blocker is not Done |
| **Blocked-by dropdown** | Picks from live task list — no ID guessing |
| **Responsive** | 3-column desktop kanban → tabbed mobile layout |
| **Metrics bar** | Live count of tasks per status + online sessions |
| **Due date** | Date + time picker, overdue badge in red |
| **Dark theme** | Obsidian Gold design system throughout |

---

## Stretch Goals

- **Debounced Autocomplete Search** — implemented.
  - The search bar now applies filtering after a 300 ms pause in typing.
  - Matching query text in task titles and descriptions is highlighted.
- **Recurring Tasks Logic** — planned.
  - Add a recurring toggle and create the next occurrence automatically when a task is completed.
- **Persistent Drag-and-Drop** — planned.
  - Allow manual task reordering and save the custom order in the backend.

## Acknowledgements

This project was completed using **Claude** for AI assistance and **Visual Studio Code** as the development environment.

## API Reference

| Method | Path | Description |
|--------|------|-------------|
| GET | /tasks | List all tasks |
| POST | /tasks | Create a task |
| PATCH | /tasks/{id} | Partial update |
| DELETE | /tasks/{id} | Delete task |
| GET | /health | Health check |
| WS | /ws | Real-time event stream |

### WebSocket events (server → client)

```json
{ "type": "task_created",    "data": { ...task } }
{ "type": "task_updated",    "data": { ...task } }
{ "type": "task_deleted",    "data": { "id": 5  } }
{ "type": "connected_count", "count": 2          }
```

---

## Task Fields

| Field | Type | Notes |
|-------|------|-------|
| `title` | string (max 160) | Required |
| `description` | string (max 5000) | Optional |
| `due_date` | ISO-8601 datetime | Optional |
| `status` | `todo` / `in_progress` / `done` | Default: `todo` |
| `blocked_by` | task ID integer | Optional; validated against real tasks |
