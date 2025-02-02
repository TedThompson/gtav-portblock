REM GTA:V Port Blocker
REM ********************
@echo off
setlocal enabledelayedexpansion
cls

REM check for elevated privileges
net session >nul 2>&1
if not %errorLevel% == 0 (
    echo Error: You must run this as administrator
    pause
    exit /b
)

REM check if windows firewall is running
sc query "MpsSvc" | find "RUNNING" >nul 2>&1
echo sc "%errorLevel%"
if "%errorLevel%" == "0" (
  netsh advfirewall show currentprofile state | find "ON" >nul 2>&1
  echo netsh "!errorLevel!"
  if not "!errorLevel!" == "0" (
    echo Error: You need to enable 
	echo Windows Firewall
    pause
    exit /b
  )
) else (
  echo Error: You need to start
  echo Windows Firewall service
  pause
  exit /b
)

set fwRule="Grand Theft Auto V by reverie"
set InputFile=%~dp0\whitelist.txt

REM Remove firewall rule if set previously
:deleteFW
cls
netsh advfirewall firewall show rule name=%fwRule% >nul 2>&1
if not %errorLevel% == 1 (
    netsh advfirewall firewall delete rule name=%fwRule%
    echo.Firewall rule deleted. The public can now
	echo.join your session.
)

:menuNone
title Public
echo.
echo =========================================
echo GTA V: Online private session by reverie
echo =========================================
echo.
echo 1) Start solo public session
echo 2) Start whitelist session
echo 5) How to use
echo 7) About
echo 0) Exit
echo.
set m=x
set /p m=Enter option: 
if %m%==1 goto startSolo
if %m%==2 goto startWhitelist
if %m%==5 goto howto
if %m%==7 goto readme
if %m%==0 goto quitScript
cls
echo.Error: Invalid option selected
goto menuNone

:menuSolo
title Solo
echo.
echo =========================================
echo GTA V: Online private session by reverie
echo =========================================
echo.
echo 1) Stop solo public session
echo.
set m=x
set /p m=Enter option: 
if %m%==1 goto deleteFW
cls
echo.Error: Invalid option selected
goto menuSolo

:menuWhitelist
title White
set refreshWhitelist=0
echo.
echo =========================================
echo GTA V: Online private session by reverie
echo =========================================
echo.
echo 2) Stop whitelist session
echo 5) Refresh/View whitelist
echo.
set m=x
set /p m=Enter option: 
if %m%==2 goto deleteFW
if %m%==5 (
    set refreshWhitelist=1
    goto startWhitelist
)
cls
echo.Error: Invalid option selected
goto menuWhitelist

:howto
cls
echo.-----------------------------
echo.How to play alone
echo.-----------------------------
echo.1. Go to GTA V: Online.
echo.2. Entering a public session, select 
echo.   "1) Start solo public session".
echo.3. Wait for a few moments for players to
echo    leave the session. Find a new session if
echo.   not.
echo.
echo.-----------------------------
echo.How to play with friends
echo.-----------------------------
echo.1. Ensure your friends' IP are put in a 
echo.   text file called "whitelist.txt".
echo.2. Follow steps in "Play alone".
echo.3. Select "1) Stop solo public session" 
echo.   and then "2) Start whitelist session".
echo.4. Invite your friends into your session 
echo.   via Steam overlay or Social Club.
echo.
echo.-----------------------------
echo.How to remove firewall rules
echo.-----------------------------
echo.1. Select "Stop whitelist session" or
echo.   "Stop solo public session".
echo.
pause
cls
goto menuNone

:readme
cls
echo.-----------------------------
echo.About
echo.-----------------------------
echo.This tool uses *Windows Firewall* to set up
echo.port blocking and whitelisting so you can 
echo.have a fun experience playing GTA V: Online 
echo.alone or with your friends. You must enable
echo.it first if you want to use this tool.
echo.
goto menuNone

:startSolo
cls
REM Create firewall rule for solo session
netsh advfirewall firewall add rule name=%fwRule% protocol=UDP dir=out action=block localport=6672
netsh advfirewall firewall add rule name=%fwRule% protocol=UDP dir=in action=block localport=6672
echo.Firewall rules set. You are now in solo 
echo public session.
goto menuSolo

:startWhitelist
cls
REM Check for whitelist.txt
if not exist %InputFile% (
    echo.
    echo.
    echo Error: You need to create whitelist.txt file
	echo.in the same directory where this program is 
	echo.run.
	echo.
    goto menuNone
)

if !refreshWhitelist!==1 (
    echo.Refreshing whitelist session
    netsh advfirewall firewall delete rule name=%fwRule%
)

REM Refresh whitelist.txt
set TmpTmpFile=%Temp%\%~n0-tmp.tmp
set TmpFile=%Temp%\%~n0.tmp
(for /f "tokens=1-4 delims=. " %%a in ('type "%InputFile%"') do (
    set Oct1=00%%a
    set Oct2=00%%b
    set Oct3=00%%c
    set Oct4=00%%d
    echo !Oct1:~-3!!Oct2:~-3!!Oct3:~-3!!Oct4:~-3!	%%a.%%b.%%c.%%d
))>"%TmpTmpFile%"
(for /f "tokens=2" %%a in ('type "%TmpTmpFile%" ^| sort.exe') do (
    echo %%a
))>"%TmpFile%"
del "%TmpTmpFile%"

REM Show IP(s) in whitelist.txt
echo.======================== IP(s) in whitelist ============================
set /a ColWidth = 3
set /a ColCount = 0
set Line=
for /f "tokens=1" %%a in ('type "%TmpFile%"') do (
    set /a ColCount += 1
    set Line=!Line!		%%a

    if !ColCount! geq !ColWidth! (
        set /a ColCount = 0
        echo.!Line:~1!
        set Line=
    )
)
if defined Line echo.%Line:~1%
echo.========================================================================

REM Prepare range of IP to block
set "fullRange="
set "startRange=1.1.1.1"
set "endRange=224.0.0.0"
set "prevset=0.0.0.-1"
set "nextset=0.0.0.1"
for /f "tokens=1" %%a in ('type "%TmpFile%"') do (

    for /f "tokens=1-4 delims=. " %%w in ("%%a") do (
        if %%z==0 (
            echo.Error: %%w.%%x.%%y.%%z is an invalid IP
            goto menuNone
        )
        for /f "tokens=1-4 delims=. " %%i in ("!prevset!") do (
            set /a octPrevA=%%w+%%i, octPrevB=%%x+%%j, octPrevC=%%y+%%k, octPrevD=%%z+%%l
            REM modify prevset if last octet is actually 1
            if %%z==1 (
                set /a octPrevC=!octPrevC!-1, octPrevD=!octPrevD!+255
                REM modify prevset if third and last octet are actually 0 and 1 e.g. 192.168.0.1
                if %%y==0 (
                    set /a octPrevB=!octPrevB!-1, octPrevC=!octPrevC!+256
                )
                REM modify prevset if all except first octet is 0 and last octet is 1 e.g. 192.0.0.1
                if %%x==0 (
                    set /a octPrevA=!octPrevA!-1, octPrevB=!octPrevB!+256
                )
            )
            set prevIP=!octPrevA!.!octPrevB!.!octPrevC!.!octPrevD!
        )
        for /f "tokens=1-4 delims=. " %%i in ("!nextset!") do (
            set /a octNextA=%%w+%%i, octNextB=%%x+%%j, octNextC=%%y+%%k, octNextD=%%z+%%l
            REM modify nextset if last octet is actually 255 e.g. 192.168.1.255
            if %%z==255 (
                set /a octNextC=!octNextC!+1, octNextD=!octNextD!-254
            )
            REM modify nextset if third and last octet are actually 255 e.g. 192.168.255.255
            if %%y==255 (
                if %%z==255 (
                    set /a octNextB=!octNextB!+1, octNextC=!octNextC!-254
                )
            )
            REM modify nextset if all are 255 e.g. 192.255.255.255
            if %%x==255 (
                if %%y==255 (
                    if %%z==255 (
                        set /a octNextA=!octNextA!+1, octNextB=!octNextB!-254
                    )
                )
            )
            set nextIP=!octNextA!.!octNextB!.!octNextC!.!octNextD!
        )
    )

    if [!fullRange!] == [] (
        set "fullRange=%startRange%-!prevIP!,!nextIP!-%endRange%"
    ) else (
        call set fullRange=%%fullRange:%endRange%=!prevIP!%%,!nextIP!-%endRange%
    )
)
del "%TmpFile%"
REM Create firewall rule for whitelist session based on range to block
netsh advfirewall firewall add rule name=%fwRule% protocol=UDP dir=out action=block localport=6672 remoteip=!fullRange!
netsh advfirewall firewall add rule name=%fwRule% protocol=UDP dir=in action=block localport=6672 remoteip=!fullRange!
echo.Firewall rules set. Only players from the whitelist can now join 
echo.your session
goto menuWhitelist

:quitScript
cls
echo.Thank you for using %fwRule%
pause
exit /b
