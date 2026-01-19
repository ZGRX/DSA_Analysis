@echo off
echo ========================================================
echo       Starting DSA Analysis System (Refactored)
echo ========================================================
echo.
echo Launching MATLAB...
echo Please wait for the MATLAB window to appear.
echo.

:: Launch MATLAB and run the main script
:: -r: Executes the command and keeps MATLAB open
:: cd('%~dp0'): Changes MATLAB's working directory to the script's location
matlab -r "cd('%~dp0'); try, DSA_Analysis_GUI_Refactored; catch ME, disp(ME.message); end;"

if %errorlevel% neq 0 (
    echo.
    echo Error: Could not launch MATLAB. 
    echo Please check if MATLAB is installed and added to your system PATH.
    echo.
    pause
)
