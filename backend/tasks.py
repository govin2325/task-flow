from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import Task
from ..schemas import TaskCreate, TaskRead, TaskUpdate
from ..ws_manager import manager

router = APIRouter(prefix="/tasks", tags=["tasks"])


def _get_task_or_404(task_id: int, db: Session) -> Task:
    task = db.get(Task, task_id)
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Task {task_id} not found.",
        )
    return task


def _validate_blocked_by(
    blocked_by: int | None, task_id: int | None, db: Session
) -> None:
    if blocked_by is None:
        return
    blocker = db.get(Task, blocked_by)
    if not blocker:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="blocked_by references a non-existent task.",
        )
    if task_id is not None and blocked_by == task_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A task cannot block itself.",
        )


def _task_to_dict(task: Task) -> dict:
    return {
        "id": task.id,
        "title": task.title,
        "description": task.description,
        "due_date": task.due_date.isoformat() if task.due_date else None,
        "status": task.status.value,
        "blocked_by": task.blocked_by,
    }


@router.get("", response_model=list[TaskRead])
def list_tasks(db: Session = Depends(get_db)):
    result = db.execute(
        select(Task).order_by(
            Task.due_date.is_(None), Task.due_date.asc(), Task.id.desc()
        )
    )
    return result.scalars().all()


@router.get("/{task_id}", response_model=TaskRead)
def get_task(task_id: int, db: Session = Depends(get_db)):
    return _get_task_or_404(task_id, db)


@router.post("", response_model=TaskRead, status_code=status.HTTP_201_CREATED)
async def create_task(payload: TaskCreate, db: Session = Depends(get_db)):
    _validate_blocked_by(payload.blocked_by, None, db)
    task = Task(
        title=payload.title,
        description=payload.description,
        due_date=payload.due_date,
        status=payload.status,
        blocked_by=payload.blocked_by,
    )
    db.add(task)
    db.commit()
    db.refresh(task)
    await manager.broadcast("task_created", _task_to_dict(task))
    return task


@router.patch("/{task_id}", response_model=TaskRead)
async def update_task(
    task_id: int, payload: TaskUpdate, db: Session = Depends(get_db)
):
    task = _get_task_or_404(task_id, db)
    data = payload.model_dump(exclude_unset=True)
    if "blocked_by" in data:
        _validate_blocked_by(data["blocked_by"], task_id, db)
    for key, value in data.items():
        setattr(task, key, value)
    db.add(task)
    db.commit()
    db.refresh(task)
    await manager.broadcast("task_updated", _task_to_dict(task))
    return task


@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_task(task_id: int, db: Session = Depends(get_db)):
    task = _get_task_or_404(task_id, db)
    db.delete(task)
    db.commit()
    await manager.broadcast("task_deleted", {"id": task_id})
