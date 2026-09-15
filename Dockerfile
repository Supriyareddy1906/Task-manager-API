FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir --target=/app/packages -r requirements.txt
COPY app ./app
COPY tests ./tests
COPY scripts ./scripts
RUN useradd -m appuser && chown -R appuser:appuser /app

ENV PYTHONPATH=/app/packages
USER appuser

EXPOSE 8000

CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]