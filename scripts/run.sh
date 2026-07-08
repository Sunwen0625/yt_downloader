#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

BACKEND_DIR="$ROOT_DIR/backend"
FRONTEND_DIR="$ROOT_DIR/frontend"

echo "=== YT Downloader Launcher ==="

cleanup() {
    echo ""
    echo "Shutting down..."
    if [ -n "$BACKEND_PID" ]; then
        kill "$BACKEND_PID" 2>/dev/null || true
        wait "$BACKEND_PID" 2>/dev/null || true
    fi
    exit 0
}
trap cleanup SIGINT SIGTERM

# Start backend
echo "[1/2] Starting backend..."
cd "$BACKEND_DIR"
if command -v poetry &> /dev/null; then
    poetry run uvicorn main:app --host 127.0.0.1 --port 8000 &
    BACKEND_PID=$!
elif command -v uvicorn &> /dev/null; then
    uvicorn main:app --host 127.0.0.1 --port 8000 &
    BACKEND_PID=$!
else
    echo "Error: poetry or uvicorn not found. Install dependencies first."
    exit 1
fi

# Wait for backend to be ready
echo "Waiting for backend..."
for i in $(seq 1 30); do
    if curl -s http://127.0.0.1:8000/docs > /dev/null 2>&1; then
        echo "Backend ready!"
        break
    fi
    if [ "$i" -eq 30 ]; then
        echo "Timeout waiting for backend."
        exit 1
    fi
    sleep 1
done

# Start frontend
echo "[2/2] Starting frontend..."
cd "$FRONTEND_DIR"
if command -v flutter &> /dev/null; then
    flutter run
else
    echo "Error: flutter not found."
    cleanup
fi
