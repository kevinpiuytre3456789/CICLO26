@echo off
cd /d "%~dp0"
if not exist .venv\Scripts\python.exe python -m venv .venv
.venv\Scripts\python.exe -c "import pyodbc" >nul 2>&1
if errorlevel 1 .venv\Scripts\python.exe -m pip install -r requirements.txt
if errorlevel 1 goto fallo
.venv\Scripts\python.exe app.py --open
if errorlevel 1 goto fallo
exit /b
:fallo
echo No se pudo iniciar la app. Revisa el mensaje anterior.
pause
