@echo off
echo Preparando proyecto Flutter...
flutter create .
if errorlevel 1 pause & exit /b 1
flutter pub get
if errorlevel 1 pause & exit /b 1
flutter test
if errorlevel 1 pause & exit /b 1
flutter run
pause
