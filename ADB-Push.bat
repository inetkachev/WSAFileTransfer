@echo off
setlocal enabledelayedexpansion
set "SendToPath=%APPDATA%\Microsoft\Windows\SendTo"
set "CurrentDir=%~dp0"


if /i "%CurrentDir%" == "%SendToPath%\" (
    goto :send_file
) else (
    rem goto :send_file 
	goto  :install_script
)

:install_script
set "ADBPath="
for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v ADBPath 2^>nul') do set "ADBPath=%%b"

if not defined ADBPath (
    echo Do you want to use the current:
    echo (%~dp0)
    echo as ADB path? (Y/N)
    choice /C YN /M "Choose Y or N:"
    if %errorlevel% equ 1 (
        set "ADBPath=%~dp0"
    ) else (
        set /p ADBPath="Enter the path to ADB: "
    )
    reg add "HKCU\Environment" /v ADBPath /t REG_SZ /d %ADBPath%
)

set "Destination=%SendToPath%\%~nx0"
copy "%~f0" "%Destination%"
echo Script has been installed to the SendTo folder. ADB path has been saved in the environment variables.
pause
exit

:send_file
set "ADBPath="
for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v ADBPath 2^>nul') do set "ADBPath=%%b"

net session >nul 2>&1 & if %errorLevel% NEQ 0 powershell -ex bypass -c Start-Process -Verb runas -FilePath '%comspec%' -ArgumentList '/c %0 %*' & exit
cd "%ADBPath%"
:device_selection
echo Please wait, getting the list of connected devices...
adb devices > devices_list.txt
echo.
set i=0
for /F "tokens=1,2" %%a in (devices_list.txt) do (
    if "%%b" == "device" (        
        call set "DeviceSerials[%%i%%]=%%a"
        call echo %%i%%. %%a
		set /a i+=1
    )
)

set DeviceSerial="0"

if %i% equ 0 (
    echo No devices found. Please connect a device and try again.
    del devices_list.txt
    pause
    exit /b
) else if %i% equ 1 (
	set "DeviceSerial=%DeviceSerials[0]%"
) else (
    set /P DeviceIndex="Enter the number of the device you want to send the file to: "
	rem call echo DS = %%DeviceSerials[!DeviceIndex!]%%
	rem echo DS0 = %DeviceSerials[0]%
	rem echo DS1 = %DeviceSerials[1]%
	rem echo DS2 = %DeviceSerials[2]%
	call set DeviceSerial=%%DeviceSerials[!DeviceIndex!]%%
)

if "%DeviceSerial%"=="0" (
	echo No serial
) else (
	echo.
	echo Device Serial: %DeviceSerial% Index: %DeviceIndex%
	echo Sending the file to the device with serial number %DeviceSerial%...
	call adb -s %DeviceSerial% push "%~1" /sdcard/Download/
)
del devices_list.txt
pause