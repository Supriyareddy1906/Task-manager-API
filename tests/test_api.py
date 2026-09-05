import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

# Point the app at an in-memory SQLite DB BEFORE importing app.main,
# so the module-level engine/create_all in database.py never tries Postgres.
os.environ["DATABASE_URL"] = "sqlite:///:memory:"

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.main import app
from app.database import Base, get_db

# Use an in-memory SQLite DB for testing (no Postgres needed in CI).
# StaticPool ensures all connections share the same in-memory DB instance.
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"
engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base.metadata.create_all(bind=engine)


def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db
client = TestClient(app)


def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_create_and_get_task():
    payload = {"title": "Write CI pipeline", "description": "Set up GitHub Actions", "priority": 1}
    response = client.post("/tasks", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["title"] == payload["title"]
    task_id = data["id"]

    response = client.get(f"/tasks/{task_id}")
    assert response.status_code == 200
    assert response.json()["id"] == task_id


def test_update_task():
    response = client.post("/tasks", json={"title": "Old title"})
    task_id = response.json()["id"]

    response = client.put(f"/tasks/{task_id}", json={"status": "done"})
    assert response.status_code == 200
    assert response.json()["status"] == "done"


def test_delete_task():
    response = client.post("/tasks", json={"title": "Temp task"})
    task_id = response.json()["id"]

    response = client.delete(f"/tasks/{task_id}")
    assert response.status_code == 204

    response = client.get(f"/tasks/{task_id}")
    assert response.status_code == 404


def test_task_not_found():
    response = client.get("/tasks/9999")
    assert response.status_code == 404


def test_simulate_error():
    response = client.get("/simulate-error")
    assert response.status_code == 500


def test_metrics_endpoint_exists():
    response = client.get("/metrics")
    assert response.status_code == 200
