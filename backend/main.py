from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware

from .database import Base, engine
from .routers.tasks import router as tasks_router
from .ws_manager import manager

Base.metadata.create_all(bind=engine)

app = FastAPI(title="TaskFlow API", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(tasks_router)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.websocket("/ws")
async def websocket_endpoint(ws: WebSocket):
    await manager.connect(ws)
    try:
        while True:
            await ws.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(ws)
        await manager.broadcast("connected_count", {"count": manager.count})
