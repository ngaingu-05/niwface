from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from datetime import datetime, timezone
from pathlib import Path
import json
import os
import re
import uuid

ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "data"
DATA_DIR.mkdir(parents=True, exist_ok=True)

app = FastAPI(title="niwface WebSocket Receiver")
SEEN_RECORD_IDS: dict[str, set[str]] = {}


def _load_seen_record_ids(filepath: Path) -> set[str]:
    seen: set[str] = set()
    if not filepath.is_file():
        return seen
    with filepath.open("r", encoding="utf-8") as records_file:
        for line in records_file:
            try:
                entry = json.loads(line)
                record_id = entry.get("payload", {}).get("uuid")
                if record_id:
                    seen.add(str(uuid.UUID(str(record_id))))
            except (json.JSONDecodeError, AttributeError, ValueError, TypeError):
                continue
    return seen

@app.get("/health")
async def health():
    return {"status": "online", "service": "niwface-websocket"}

@app.websocket("/ws/arkit/{session_id}")
async def arkit_receiver(websocket: WebSocket, session_id: str):
    if not re.fullmatch(r"[a-zA-Z0-9_-]{1,80}", session_id):
        await websocket.close(code=1008)
        return

    await websocket.accept()
    filepath = DATA_DIR / f"{session_id}.jsonl"
    if session_id not in SEEN_RECORD_IDS:
        SEEN_RECORD_IDS[session_id] = _load_seen_record_ids(filepath)
    seen_record_ids = SEEN_RECORD_IDS[session_id]

    try:
        while True:
            payload = await websocket.receive_json()
            if not isinstance(payload, dict):
                await websocket.close(code=1003, reason="Expected a JSON object")
                return
            if payload.get("type") == "ping":
                await websocket.send_json({"success": True, "type": "pong"})
                continue
            try:
                record_id = str(uuid.UUID(str(payload.get("uuid", ""))))
            except (ValueError, AttributeError, TypeError):
                await websocket.close(code=1008, reason="Recording must contain a valid uuid")
                return

            # A reconnect may resend a sample whose acknowledgement was lost.
            # Record UUIDs make that retry idempotent in the JSONL file.
            if record_id not in seen_record_ids:
                record = {
                    "received_at": datetime.now(timezone.utc).isoformat(),
                    "session_id": session_id,
                    "source": "arkit",
                    "payload": payload
                }

                with filepath.open("a", encoding="utf-8") as f:
                    f.write(json.dumps(record, ensure_ascii=False) + "\n")
                    f.flush()
                    os.fsync(f.fileno())
                seen_record_ids.add(record_id)

            await websocket.send_json({"success": True, "uuid": record_id})

    except WebSocketDisconnect:
        print(f"Disconnected: {session_id}")
