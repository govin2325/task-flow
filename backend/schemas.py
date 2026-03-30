from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator

from .models import TaskStatus


class TaskBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=160)
    description: str = Field(default="", max_length=5000)
    due_date: Optional[datetime] = None
    status: TaskStatus = TaskStatus.TODO
    blocked_by: Optional[int] = None

    @field_validator("title")
    @classmethod
    def validate_title(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("Title cannot be empty.")
        return value


class TaskCreate(TaskBase):
    pass


class TaskUpdate(BaseModel):
    title: Optional[str] = Field(default=None, min_length=1, max_length=160)
    description: Optional[str] = Field(default=None, max_length=5000)
    due_date: Optional[datetime] = None
    status: Optional[TaskStatus] = None
    blocked_by: Optional[int] = None

    @field_validator("title")
    @classmethod
    def validate_title(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return value
        value = value.strip()
        if not value:
            raise ValueError("Title cannot be empty.")
        return value


class TaskRead(TaskBase):
    id: int

    model_config = ConfigDict(from_attributes=True)
