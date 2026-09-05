import logging
import random
import time

from fastapi import FastAPI, HTTPException, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from prometheus_fastapi_instrumentator import Instrumentator

from . import models, schemas, crud
from .database import engine, get_db

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("task-manager-api")

# Create DB tables on startup
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Task Manager API", version="1.0.0")

# Expose /metrics automatically in Prometheus format
Instrumentator().instrument(app).expose(app, endpoint="/metrics")


@app.get("/health")
def health_check(db: Session = Depends(get_db)):
    """Used by monitoring / load balancer / uptime checks."""
    try:
        db.execute(text("SELECT 1"))
        db_status = "ok"
    except Exception as e:
        logger.error(f"DB health check failed: {e}")
        db_status = "unreachable"
        raise HTTPException(status_code=503, detail={"status": "unhealthy", "db": db_status})
    return {"status": "healthy", "db": db_status}


@app.get("/")
def root():
    return {"message": "Task Manager API is running"}


# ---------- Task CRUD ----------

@app.post("/tasks", response_model=schemas.TaskOut, status_code=201)
def create_task(task: schemas.TaskCreate, db: Session = Depends(get_db)):
    return crud.create_task(db, task)


@app.get("/tasks", response_model=list[schemas.TaskOut])
def list_tasks(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return crud.get_tasks(db, skip, limit)


@app.get("/tasks/{task_id}", response_model=schemas.TaskOut)
def get_task(task_id: int, db: Session = Depends(get_db)):
    task = crud.get_task(db, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return task


@app.put("/tasks/{task_id}", response_model=schemas.TaskOut)
def update_task(task_id: int, task: schemas.TaskUpdate, db: Session = Depends(get_db)):
    updated = crud.update_task(db, task_id, task)
    if not updated:
        raise HTTPException(status_code=404, detail="Task not found")
    return updated


@app.delete("/tasks/{task_id}", status_code=204)
def delete_task(task_id: int, db: Session = Depends(get_db)):
    deleted = crud.delete_task(db, task_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Task not found")
    return None


# ---------- Chaos endpoints (for demoing monitoring/alerts live) ----------

@app.get("/simulate-error")
def simulate_error():
    """Deliberately throws a 500 so you can trigger an alert during your demo."""
    logger.error("Simulated error triggered manually")
    raise HTTPException(status_code=500, detail="Simulated internal server error")


@app.get("/simulate-slow")
def simulate_slow():
    """Deliberately slow response so you can demo latency alerts."""
    delay = random.uniform(2, 5)
    time.sleep(delay)
    return {"message": f"Responded slowly after {delay:.2f}s"}
