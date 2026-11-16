@echo off
REM Development mode: backend with auto-reload (new window) + Vite dev server with hot reload.
cd /d "%~dp0"
start "Traffic AI backend" cmd /k .venv\Scripts\python.exe -m uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload
cd frontend
call npm run dev
