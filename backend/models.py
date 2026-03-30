import enum
from datetime import datetime
from typing import Optional

from sqlalchemy import DateTime, Enum, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .database import Base


class TaskStatus(str, enum.Enum):
    TODO = "todo"
    IN_PROGRESS = "in_progress"
    DONE = "done"


class Task(Base):
    __tablename__ = "tasks"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    title: Mapped[str] = mapped_column(String(160), nullable=False)
    description: Mapped[str] = mapped_column(Text, default="", nullable=False)
    due_date: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    status: Mapped[TaskStatus] = mapped_column(
        Enum(TaskStatus, name="taskstatus"),
        default=TaskStatus.TODO,
        nullable=False,
    )
    blocked_by: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("tasks.id", ondelete="SET NULL"), nullable=True
    )

    blocker: Mapped[Optional["Task"]] = relationship(
        "Task", remote_side=[id], foreign_keys=[blocked_by]
    )
