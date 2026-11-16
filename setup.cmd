@echo off
REM One-time setup: Python virtual environment + backend packages + frontend build.
cd /d "%~dp0"
echo [1/4] Creating Python virtual environment (.venv)...
if not exist .venv\Scripts\python.exe (
  py -3 -m venv .venv || python -m venv .venv || goto :error
)
echo [2/4] Installing backend packages...
.venv\Scripts\python.exe -m pip install --disable-pip-version-check -r requirements.txt || goto :error
echo [3/4] Installing frontend packages...
cd frontend
call npm install --no-audit --no-fund || goto :error
echo [4/4] Building the dashboard...
call npm run build || goto :error
cd ..
echo.
echo Setup complete. Start the app with:  start.cmd
exit /b 0
:error
echo.
echo Setup failed - see the message above.
exit /b 1
