@echo off
echo Building APK...
call flutter build apk --debug
if %errorlevel% neq 0 exit /b %errorlevel%

echo Waiting for device...
adb wait-for-device

echo Installing APK...
:retry
adb install -r build\app\outputs\flutter-apk\app-debug.apk
if %errorlevel% neq 0 (
    echo Install failed, retrying in 3s...
    timeout /t 3 /nobreak >nul
    adb wait-for-device
    goto retry
)

echo Setting up tunnel...
adb reverse tcp:8000 tcp:8000

echo Launching app...
adb shell am start -n com.carbontech.app/com.carbontech.app.MainActivity

echo Attaching debugger...
flutter attach
