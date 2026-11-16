@echo off
REM Starts the backend, which also serves the built dashboard on port 8000.
cd /d "%~dp0"
if not exist frontend\dist\index.html (
  echo The dashboard is not built yet. Run setup.cmd first.
  exit /b 1
)
echo.
echo  Dashboard on this PC:      http://localhost:8000
echo  On iPhone (same Wi-Fi):    http://YOUR-PC-IP:8000   (find the IP with: ipconfig)
echo  API documentation:         http://localhost:8000/docs
echo  Press Ctrl+C to stop.
echo.
.venv\Scripts\python.exe -m uvicorn backend.main:app --host 0.0.0.0 --port 8000
