::  Source code of MicroflashOS
::  A "fantasy operating system" made by KNBnoob1!
::  Website: https://knbn1.github.io

@echo off

:: Define some version strings

set "mfosver=2026.05.04"
set "fbver=5.2"
set "pkgrepo=GigaflashOS Unified Repository [Revision 2]"

:: Define default directories

set "sysdir=mfos"
set "modsdir=usermods"
set "userdata=userdata"
set "usrsysdata=mfosdata"
set "disk0label=MicroflashOS"

::Update cleanup
if "%1"=="UPDATE" if exist mfos-latest.old (
    del installer.bat mfos-latest.old
    echo.
    echo Update completed!
    echo You are now on %mfosver%
    echo.
    pause
)

:: Boot process stage 0 - Bootloader

:bootstagezero

cd /d "%~dp0"
title MicroflashOS Bootloader

:: System disk stuffs

set "disk0=%~dp0%disk0label%"
set "disk0p1=%disk0%/%sysdir%"
set "disk0p2=%disk0%/%userdata%"

:: Special directories

set "devices=%disk0p1%/devices"
set "usrdir=%disk0p2%/%username%"
set "usrsysdatadir=%usrdir%/%usrsysdata%"
set "toggles=%usrsysdatadir%/toggles"
set "usrmods=%usrsysdatadir%/%modsdir%"
set "pkgdir=%usrsysdatadir%/packages"
set "pkgmeta=%pkgdir%/installed"

:: Startup parameters

if exist "%toggles%/echoon" (@echo on)
if not exist "%toggles%/noclear" (cls)
if not exist "%toggles%/nolog" (set "logfile=%~dp0mfos-log.txt") else (set "logfile=NUL")
if not exist "%toggles%/incognito" (set "history=%usrdir%/mfos-history.txt") else (set "history=NUL")

:: Start logging

echo. >>"%logfile%"
echo %time% %date% >>"%logfile%"
echo ========================================= >>"%logfile%"
echo [bootloader] INFO: to log or not to log, that is the question >>"%logfile%"
echo [bootloader] INFO: logging system initialized
echo [bootloader] INFO: log file: %logfile%

if exist "%toggles%/slowboot" (call :slowboot)

:: Transfer control to kernel

echo [bootloader] INFO: loading bundled kernel into memory... >>"%logfile%"
echo [kernel] INFO: hello world, my version is %mfosver% >>"%logfile%"
echo [kernel] INFO: terminating bootloader... done >>"%logfile%"
echo.

:: System disk check


title Finding system disk...
if exist "%disk0label%" (
    echo System disk "%disk0label%" mounted as /
    echo [kernel] INFO: system disk is "%disk0label%" mounted as / >>"%logfile%"
) else (
    echo Unable to mount system disk!
    echo [kernel] ERROR: system disk mount failure >>"%logfile%"
    goto bootfail
)

:: Version check

set /p oldver=<"%disk0label%/version.txt"
echo.
echo Checking version strings...
echo.
echo Bundled kernel: %mfosver%
echo Detected kernel: %oldver%
echo.
if "%oldver%" == "%mfosver%" (
    echo MicroflashOS is on the latest version!
    echo [kernel] INFO: version string valid >>"%logfile%"
) else (
    echo Version mismatch!
    echo [kernel] ERROR: expected "%mfosver%" but got "%oldver%" >>"%logfile%"
    goto bootfail
)

:: Boot process stage 1 - Initialize devices

:bootstageone

echo [kernel] INFO: begin boot process stage 1 >>"%logfile%"

if exist "%toggles%/slowboot" (call :slowboot)

echo.
title Initializing devices...
echo Initializing devices...
echo.

if not exist "%devices%" (cd /d "%disk0p1%" && md devices)
if not exist "%devices%/mem" (cd /d "%devices%" && md mem)

echo System disk - /%sysdir%/>"%devices%/disk0p1"
if not exist "%devices%/disk0p1" (call :devinitfail disk0p1)
echo INIT "disk0p1"
echo [kdevinit] INFO: system partition initialized >>"%logfile%"

echo Memory sector 1 - Core system>"%devices%/mem/memsect1"
if not exist "%devices%/mem/memsect1" (call :devinitfail memsect1)
echo INIT "memsect1"
echo [kdevinit] INFO: memory sector 1 initialized >>"%logfile%"

echo Memory sector 2 - Userspace>"%devices%/mem/memsect2"
if not exist "%devices%/mem/memsect2" (call :devinitfail memsect2)
echo INIT "memsect2"
echo [kdevinit] INFO: memory sector 2 initialized >>"%logfile%"

echo Memory sector 3 - Secret Block>"%devices%/mem/memsect3"
if not exist "%devices%/mem/memsect3" (call :devinitfail memsect3)
echo INIT "memsect3"
echo [kdevinit] INFO: memory sector 3 initialized >>"%logfile%"

echo Human Interface Devices>"%devices%/hids"
if not exist "%devices%/hids" (call :devinitfail hids)
echo INIT "hids"
echo [kdevinit] INFO: human interface devices initialized >>"%logfile%"

echo Auditory devices: headphones, speakers, microphones, etc.>"%devices%/audio"
if not exist "%devices%/audio" (call :devinitfail audio)
echo INIT "audio"
echo [kdevinit] INFO: audio subsystem initialized >>"%logfile%"

if exist "%toggles%/slowboot" (call :slowboot)

:: Boot process stage 2 - Load core modules

:bootstagetwo

echo [kernel] INFO: begin boot process stage 2 >>"%logfile%"

echo.
title Loading core modules...
echo Loading core modules...
echo.

for %%C in (kernel recovery core fsutils ltmem stmem cmd compact proctector mfpkg sensors audio graphics) do (
    if exist "%disk0p1%/%%C.mcm" (call :loadmodok /%sysdir%/%%C.mcm) else (call :loadmodfail /%sysdir%/%%C.mcm)
)

if exist "%toggles%/slowboot" (call :slowboot)

:: Boot process stage 3 - Userdata partition

:bootstagethree

echo [kernel] INFO: begin boot process stage 3 >>"%logfile%"

title Checking userdata partition...

echo.
if exist "%disk0p2%" (
    echo Userdata partition>"%devices%/disk0p2"
    echo Userdata partition is /%userdata%/
    echo [kdevinit] INFO: userdata partition initialized >>"%logfile%"
)

:: Userdata generation

if not exist "%disk0p2%" (
    echo Userdata partition not found!
    echo [kdevinit] WARN: failed to initialize userdata partition >>"%logfile%"
    echo.
    echo Creating userdata partition...
    echo [kusrinit] INFO: creating userdata partition >>"%logfile%"
    cd /d "%disk0%"
    md "%userdata%"
    echo Userdata partition>"%devices%/disk0p2"
    echo.
    if not exist "%disk0p2%" (
        echo Userdata partition creation failed!
        echo [kusrinit] ERROR: userdata partition creation failed >>"%logfile%"
        call :pauseexit
    )
)

if not exist "%usrdir%" (
    echo Userdata for user %username% not found!
    echo [kusrinit] WARN: no userdata found for user %username% >>"%logfile%"
    echo.
    echo Creating userdata for %username%...
    echo [kusrinit] INFO: creating userdata for user %username% >>"%logfile%"
    cd /d "%disk0p2%"
    md %username%
    echo.
    if not exist "%usrdir%/" (
        echo Userdata creation failed!
        echo [kusrinit] ERROR: userdata creation for user %username% failed >>"%logfile%"
        call :pauseexit
    )
)

if not exist "%usrsysdatadir%" (
    echo Setting up userdata for %username%...
    echo [kusrinit] INFO: setting up userdata for %username% >>"%logfile%"
    cd /d "%usrdir%"
    md "%usrsysdata%"
    echo.
    if not exist "%usrsysdatadir%/" (
        echo Userdata creation failed!
        echo [kusrinit] ERROR: userdata creation for user %username% failed >>"%logfile%"
        call :pauseexit
    )
)

if not exist "%toggles%/" (
    echo Creating toggle directory...
    echo [kusrinit] INFO: creating toggle directory for %username% >>"%logfile%"
    cd /d "%usrsysdatadir%"
    md toggles
    echo.
    if not exist "%usrsysdatadir%/toggles" (
        echo Toggle directory creation failed!
        echo [kusrinit] ERROR: toggle directory creation for user %username% failed >>"%logfile%"
        call :pauseexit
    )
)

if not exist "%pkgdir%/" (
    echo Creating package directory...
    echo [kusrinit] INFO: creating package directory for %username% >>"%logfile%"
    cd /d "%usrsysdatadir%"
    md packages
    cd /d "%pkgdir%"
    md installed
    echo.
    if not exist "%pkgdir%/" if not exist "%pkgmeta%" (
        echo Package directory creation failed!
        echo [kusrinit] ERROR: package directory creation for user %username% failed >>"%logfile%"
        call :pauseexit
    )
)

if not exist "%usrmods%/" (
    echo Creating module directory...
    echo [kusrinit] INFO: creating module directory for %username% >>"%logfile%"
    cd /d "%usrsysdatadir%"
    md %modsdir%
    echo.
    if not exist "%usrmods%/" (
        echo Module directory creation failed!
        echo [kusrinit] ERROR: module directory creation for user %username% failed >>"%logfile%"
        call :pauseexit
    )
)

if exist "%usrdir%" (
    echo Logging in as %username%
    echo [kusrinit] INFO: logging in as %username% >>"%logfile%"
)

if exist "%toggles%/slowboot" (call :slowboot)
echo.

:: Load user modules

for %%U in (flashbreak devtools) do (
    if exist "%usrmods%/%%U.mfm" (call :loadmodok /%userdata%/%username%/%usrsysdata%/%modsdir%/%%U.mfm)
)

if exist "%toggles%/slowboot" (call :slowboot)

:: F145HBR34K stage 3 patcher

:bootstagethree-fbpatch

if exist "%usrmods%/devtools.mfm" (
    if exist "%usrmods%/devtools.mfm" if exist "%usrmods%/flashbreak.mfm" (
    title F145HBR34K Stage 3 Intervention
    echo.
    echo Loading F145HBR34K...
    echo [fb-s3init] INFO: loading jailbreak... >>"%logfile%"
    echo.
    set "fbloaded=nope"
    echo [fb-s3init] INFO: loading module patches... >>"%logfile%"
    for %%F in (cmd fsutils proctector) do (
    if not exist "%disk0p1%/%%F.mcm" (call :fbpatchfail /%sysdir%/%%F.mfm)
        echo Patching /%sysdir%/%%F.mcm
        echo Injected F145HBR34K code into module.>"%disk0p1%/%%F.mcm"
        echo [fb-s3init] INFO: patched /%sysdir%/%%F.mcm >>"%logfile%"
    )
    if not exist "%usrmods%/devtools.mfm" (call :fbpatchfail /%userdata%/%usrsysdata%/packages/devtools.mfm)
        echo Patching /%sysdir%/%modsdir%/devtools.mfm
        echo Injected F145HBR34K code into module.>"%usrmods%/devtools.mfm"
        echo [fb-s3init] INFO: patched /%userdata%/%usrsysdata%/packages/devtools.mfm >>"%logfile%"
        echo.
        echo Patches complete!
        echo [fb-s3init] INFO: patches complete >>"%logfile%"
        echo.
        set "fbloaded=yessir"
        echo Resuming boot process...
        echo [fb-s3init] INFO: resuming boot process >>"%logfile%"
        if exist "%toggles%/slowboot" (call :slowboot)
    )
)

:: Boot process complete!

:bootcomplete

title Boot process complete!
echo.
echo MicroflashOS system files loaded!
echo [kernel] INFO: boot process completed >>"%logfile%"
cd /d "%usrdir%"

if exist "%toggles%/slowboot" (call :slowboot)

:: Welcome messages

if not exist "%toggles%/noclear" (cls)
echo.
if not exist "%disk0p1%/cmd.mcm" (
    echo [kernel] ERROR: could not load /%sysdir%/cmd.mcm >>"%logfile%"
    echo Command line could not be loaded.
    goto :pauseexit
)
echo Welcome to MicroflashOS!
echo [cmd] INFO: initialized prompt >>"%logfile%"
echo.
if not exist "%usrdir%" (
    echo Userdata for user %username% not found.
    echo [kusrinit] ERROR: no userdata for user %username% >>"%logfile%"
    echo.
    goto reboot
)
echo Logged in as %username%
echo [cmd] INFO: current user: %username% >>"%logfile%"
echo.
echo Type HELP for a list of commands.
echo Commands are not case-sensitive.

:: User prompt

:prompt

if not exist "%disk0p1%/cmd.mcm" (
    echo [kernel] ERROR: could not load /%sysdir%/cmd.mcm >>"%logfile%"
    echo Command line could not be loaded.
    goto :pauseexit
)

:: check if a reboot has been enforced

if "%enforcereboot%" == "true" (
    echo The system will now reboot.
    call :halt
    set "enforcereboot=false"
    title Rebooting...
    echo [kernel] INFO: intercepted reboot request >>"%logfile%"
    goto bootstagezero
)

:: Titlebar stuff

set "titlebar=MicroflashOS %mfosver%"
title %titlebar%
if exist "%usrmods%/devtools.mfm" (title %titlebar% [DevTools])
if "%fbloaded%"=="yessir" (
    title %titlebar% [DevTools] [F145HBR34K %fbver%]
    echo [flashbreak] INFO: modified titlebar >>"%logfile%"
)
if exist "%toggles%/showdir" (
    echo [cmd] DEBUG: showing current directory >>"%logfile%"
    echo Current directory: %cd%
    echo.
)

:: Reset last run command variable

set "input="
set "command="

:: Command whitelist

set "cmdlist=about help clock clear reboot shutdown mkdir rename delete list cd home homewipe mfpkg mountsys modules toggles nuke dumper winflash mountvirt getargs getvars update"

:: receive input from the user:

echo.

echo [cmd] INFO: load user prompt >>"%logfile%"
echo [cmd] INFO: waiting for user input >>"%logfile%"

set /p "input=%username%@%userdomain%: "

title Processing command...
echo [cmd] INFO: received command "%input%" >>"%logfile%"

:: analysis with "for"

for /f "tokens=1 delims= " %%a in ("%input%") do (set "command=%%a")

echo [cmd] DEBUG: extracted main command "%command%" >>"%logfile%"

:: compare %command% with command list

echo [cmd] DEBUG: checking "%command%" against whitelist >>"%logfile%"

set "found=nope"

for %%w in (%cmdlist%) do (
    if /i "%command%"=="%%w" set "found=yep"
)
if "%found%"=="nope" (
    echo.
    call :nocommand
    goto prompt
)
:: use call command
echo.
call :%input%
goto prompt

:: Main help section

:help
if not exist "%disk0p1%/core.mcm" (goto nocommand)
call :cmdok
echo Utilities:
echo.
echo about: Show some system info
echo update: Automatically updates to the latest version
echo clock: Print current date and time
echo clear: Clear console output
echo.
echo Power options:
echo.
echo reboot [recovery]: Reboot
echo shutdown: Power off
echo.
echo [help] INFO: load help section for /%sysdir%/core.mcm >>"%logfile%"
if exist "%disk0p1%/fsutils.mcm" (
    echo File management:
    echo.
    echo mkdir [directory]: Create a directory
    echo rename [target] [new name] Rename something to another thing
    echo delete [file/directory] [name]: Delete a file/directory
    echo list: List available files/directories
    echo cd [path]: Change to a directory
    echo home: Quickly return to user directory
    echo homewipe: Wipe all user directories
    echo [help] INFO: load help section for /%sysdir%/fsutils.mcm >>"%logfile%"
)
if exist "%usrmods%/devtools.mfm" (
    echo.
    echo Developer commands:
    echo.
    echo mountsys: Mount and modify system disk contents
    echo modules: List all core and user modules
    echo toggles [create/delete/enabled/list] [toggle]: Manage toggles
    echo getargs [arguments]: Sanity check to analyse arguments passed
    echo getvars: Print a list of ALL environment variables accessible
    echo [help] INFO: load help section for /%sysdir%/%modsdir%/devtools.mfm >>"%logfile%"
)
if exist "%disk0p1%/mfpkg.mcm" (
    echo.
    echo Package management:
    echo.
    echo mfpkg [install/uninstall/list/available] [package ID]: Package management
    echo.
    echo [help] INFO: load help section for /%sysdir%/mfpkg.mcm >>"%logfile%"
    echo Commands for installed packages:
    echo.
    if exist "%pkgdir%/nuke.mfp" (
        echo nuke: Nuke.
        echo [mfpkg] INFO: found package /%userdata%/%username%/%usrsysdata%/packages/nuke.mfp >>"%logfile%"
    )
    if exist "%pkgdir%/dumper.mfp" (
        echo dumper: MicroflashOS firmware dumper by nsp
        echo [mfpkg] INFO: found package /%userdata%/%username%/%usrsysdata%/packages/dumper.mfp >>"%logfile%"
    )
    if exist "%pkgdir%/winflash.mfp" (
        echo winflash: WinFlash compatibility layer for Windows software
        echo [mfpkg] INFO: found package /%userdata%/%username%/%usrsysdata%/packages/winflash.mfp >>"%logfile%"
    )
    if exist "%pkgdir%/mountvirt.mfp" (
        echo mountvirt [disk name]: Mount and boot to a system disk of your choice
        echo [mfpkg] INFO: found package /%userdata%/%username%/%usrsysdata%/packages/mountvirt.mfp >>"%logfile%"
    )
)
goto execdone


:update
setlocal EnableDelayedExpansion

:: updater links
set batLink="https://raw.githubusercontent.com/knbn1/mfos/refs/heads/main/mfos-latest.bat"
set metaLink="https://raw.githubusercontent.com/knbn1/mfos/refs/heads/main/mfos-latest.meta"

set "latestVersion="
set "return="

call :curl_check return
if "%return%"=="nope" (
    echo curl not found or inaccessible.
    set /p conf="Install curl via winget?(y/[n])"
    if not "%conf%"=="y" (goto :eof)
    winget install -e --id curl.curl --silent --accept-source-agreements --accept-package-agreements || goto :eof
)

echo.
echo Checking for latest updates...
curl -sSf -o "mfos-latest.meta" %metaLink% 2> curl.ERR

call :file_empty "curl.ERR" return
if "%return%"=="nope" (
    type curl.ERR >> %logfile%
    echo Version check failed. Below are the details of the error:
    type curl.ERR
    
    del curl.ERR & goto :eof
)

set /a metaLineCount=0
for /f "delims=" %%i in (mfos-latest.meta) do (
    set /a metaLineCount+=1
    :: can expand depending on .meta file
    if !metaLineCount! == 1 (
        set "latestVersion=%%i"
    )
) & del mfos-latest.meta

call :date_GEQ %mfosver% %latestVersion% yessir return
if "%return%"=="yessir" (
    echo No newer versions found -- You are up-to-date!
    goto :eof
)

echo Latest Version Found: %latestVersion%
set /p conf="Install update?([y]/n):"
if "%conf%"=="n" (goto :eof)

echo Downloading latest version...
curl -sSf -o TEMP_mfos-latest.bat %batLink% 2> curl.ERR

call :file_empty "curl.ERR" return
if "%return%"=="nope" (
    type curl.ERR >> %logfile%
    echo Update download failed. Below are the details of the error:
    type curl.ERR

    del curl.ERR & goto :eof
) & del curl.ERR

move /y TEMP_mfos-latest.bat "%~dp0"
cd /d "%~dp0"

::Hard-coded installer - Separate in the future
echo @echo off > installer.bat
echo echo. >> installer.bat
echo echo Installing update... >> installer.bat
echo ren mfos-latest.bat mfos-latest.old >> installer.bat
echo ren TEMP_mfos-latest.bat mfos-latest.bat >> installer.bat
echo mfos-latest.bat UPDATE >> installer.bat

installer.bat & goto :eof
::bye bye old version


:curl_check
:: check for curl so we can do online stuffs
:: %1=return var(bool)
    echo [updater] INFO: Checking for curl... >> %logfile%
    curl --version >nul 2>&1
    if %errorlevel% neq 0 (
        echo [updater] ERROR: curl not found. >> %logfile%
        set "%1=nope"
        goto :eof
    )
    echo [updater] INFO: curl is already installed. >> %logfile%
    set "%1=yessir"
    goto :eof

:file_empty
:: %1=filenameset(QUOTED) | %2=return(bool)
    for /f "usebackq" %%i in (%1) do (
        set "%2=nope" & goto :eof
    )
    set "%2=yessir" & goto :eof

:date_GEQ
:: Date format: YYYY.MM.DD (padded zeros)
:: %1=date 1, %2=date 2, %3=use equal?(bool) | %4=return(bool)
:: Swap dates to flip the inequality
    if "%1" GTR "%2" (set "%4=yessir" & goto :eof)
    if "%3"=="yessir" if "%1"=="%2" (set "%4=yessir" & goto :eof)
    set "%4=nope"
    goto :eof


:: About me

:about
if not exist "%disk0p1%/core.mcm" (goto nocommand)
call :cmdok
echo MicroflashOS version: %mfosver%
echo [about] INFO: mfos version is %mfosver% >>"%logfile%"
if exist "%usrmods%/devtools.mfm" (
    if "%fbloaded%"=="yessir" (
        echo F145HBR34K version: %fbver%
        echo [about] INFO: flashbreak version is %mfosver% >>"%logfile%"
    )
)
echo Mounted system disk: %disk0label%
echo [about] INFO: mounted system disk is %disk0label% >>"%logfile%"
echo.
echo Hostname: %userdomain%
echo [about] INFO: hostname is %userdomain% >>"%logfile%"
echo Processor: %processor_identifier% (%NUMBER_OF_PROCESSORS% cores)
echo [about] INFO: processor is %processor_identifier% with %NUMBER_OF_PROCESSORS% cores >>"%logfile%"
echo Architecture: %processor_architecture%
echo [about] INFO: architecture is %processor_architecture% >>"%logfile%"
echo.
echo Made by Kenneth White.
if "%fbloaded%"=="yessir" (
    echo Jailbreak by Team Centurion with help from Team Starburst.
    echo Special thanks to nsp and the GigaflashOS devs!
)
goto execdone

:clock
if not exist "%disk0p1%/core.mcm" (goto nocommand)
call :cmdok
echo Time: %time%
echo Date: %date%
echo [clock] INFO: fetched time is %time% and date is %date% >>"%logfile%"
goto execdone

:: Clear the shell

:clear
if not exist "%disk0p1%/core.mcm" (goto nocommand)
call :cmdok
if not exist "%toggles%/noclear" (
    cls
    echo [cmd] INFO: user requested shell clearance >>"%logfile%"
)
goto execdone

:: Power options

:reboot
if "%1" == "recovery" (
    echo Rebooting to recovery mode...
    echo [kernel] INFO: rebooting to recovery >>"%logfile%"
    goto recovery
)
set "enforcereboot=true"
goto :eof

:shutdown
call :cmdok
title Shutting down...
echo Shutting down...
echo [kernel] INFO: intercepted shutdown request >>"%logfile%"
exit

:: File manager

:mkdir
if not exist "%disk0p1%/fsutils.mcm" (goto nocommand)
call :cmdok
title File Manager
if "%1"=="" (
    echo This command is used to make a directory.
    echo.
    echo Usage:
    echo.
    echo mkdir [directory]
    echo [fsutils] ERROR: no directory provided >>"%logfile%"
    goto execdone
)
if exist "%1/" (
    echo Directory "%1" already exists!
    echo [fsutils] ERROR: directory "%1" already exists >>"%logfile%"
    goto execdone
)
mkdir "%1"
if not exist "%1/" (
    echo Failed to create directory "%1"!
    echo [fsutils] ERROR: failed to create directory "%1" >>"%logfile%"
    goto execdone
)
echo Created directory "%1"
echo [fsutils] INFO: created directory "%1" >>"%logfile%"
goto execdone

:rename
if not exist "%disk0p1%/fsutils.mcm" (goto nocommand)
call :cmdok
title File Manager
if "%1"=="" (
    echo This command renames a file or a folder.
    echo.
    echo Usage:
    echo.
    echo rename [target] [new name]
    echo [fsutils] ERROR: no option selected >>"%logfile%"
    goto execdone
)
if not exist "%1" (
    echo Target does not exist!
    echo [fsutils] ERROR: target "%1" does not exist >>"%logfile%"
    goto execdone
)
if exist "%2" (
    echo An object with the same name is already present!
    echo [fsutils] ERROR: new name "%2" matches an existing name >>"%logfile%"
    goto execdone
)
ren "%1" "%2"
if not exist "%2" (
    echo Failed to rename "%1"!
    echo [fsutils] ERROR: failed to rename "%1" >>"%logfile%"
    goto execdone
)
echo Renamed "%1" to "%2"
echo [fsutils] INFO: renamed "%1" to "%2" >>"%logfile%"
goto execdone

:delete
if not exist "%disk0p1%/fsutils.mcm" (goto nocommand)
call :cmdok
title File Manager
if "%1"=="" (
    echo This command deletes something.
    echo.
    echo Usage:
    echo.
    echo delete [file/directory] [name]
    echo [fsutils] ERROR: no option selected >>"%logfile%"
    goto execdone
)
if "%1"=="file" (
    if not exist "%2" (
        echo File does not exist!
        echo [fsutils] ERROR: specified file "%1" does not exist >>"%logfile%"
        goto execdone
    )
    del "%2" /f /q
    if not exist "%2" (
        echo Deleted file "%2"
        echo [fsutils] INFO: deleted file "%2" >>"%logfile%"
        goto execdone
    )
    echo Failed to delete file!
    echo [fsutils] ERROR: failed to delete file "%2" >>"%logfile%"
    goto execdone
)
if "%1"=="directory" (
    if not exist "%2" (
        echo Directory does not exist!
        echo [fsutils] ERROR: specified directory "%1" does not exist >>"%logfile%"
        goto execdone
    )
    rd "%2" /s /q
    if not exist "%2/" (
        echo Deleted directory "%2/"
        echo [fsutils] INFO: deleted directory "%2" >>"%logfile%"
        goto execdone
    )
    echo Failed to delete directory!
    echo [fsutils] ERROR: failed to delete directory "%2" >>"%logfile%"
    goto execdone
)
echo Invalid arguments.
echo [fsutils] ERROR: invalid arguments >>"%logfile%"
goto execdone

:list
if not exist "%disk0p1%/fsutils.mcm" (goto nocommand)
call :cmdok
title File Manager
echo [fsutils] INFO: listing objects in "%cd%" >>"%logfile%"
echo Directories:
echo.
dir /a:d /b
echo.
echo Files:
echo.
dir /a:-d /b
goto execdone

:cd
if not exist "%disk0p1%/fsutils.mcm" (goto nocommand)
call :cmdok
title File Manager
if "%1"=="" (
    echo This command is used to enter a directory or change your current directory.
    echo.
    echo Usage:
    echo.
    echo cd [path]
    echo [fsutils] ERROR: no path provided >>"%logfile%"
    goto execdone
)
if not exist "%1/" (
    echo Directory invalid!
    echo [fsutils] ERROR: invalid path >>"%logfile%"
    goto execdone
)
cd "%1"
echo Changed directory to "%1"
echo [fsutils] INFO: changed directory to "%1" >>"%logfile%"
echo [fsutils] DEBUG: current path is "%cd%" >>"%logfile%"
goto execdone

:: Userdata management

:home
if not exist "%disk0p1%/fsutils.mcm" (goto nocommand)
call :cmdok
title File Manager
if not exist "%usrdir%" (
    echo.
    echo Userdata for current user not found!
    echo [fsutils] ERROR: could not find userdata for current user >>"%logfile%"
    goto execdone
)
cd /d "%usrdir%"
echo Welcome home.
echo [fsutils] INFO: reverted current path to home directory >>"%logfile%"
echo [fsutils] DEBUG: current path is "%cd%" >>"%logfile%"
goto execdone

:homewipe
if not exist "%disk0p1%/fsutils.mcm" (goto nocommand)
call :cmdok
title File Manager
echo This command wipes userdata for all users, both logged out and logged in.
echo This effectively returns MicroflashOS to a "clean" state.
echo Back up any data before continuing!
echo.
call :userauth
if "%authorized%" == "true" (
    echo.
    if not exist "%disk0p2%" (
        echo Userdata partition not found!
        echo [fsutils] ERROR: could not load userdata partition >>"%logfile%"
        goto execdone
    )
    echo Found users:
    dir /a:d /b "%disk0p2%"
    echo.
    echo Wiping userdata...
    cd /d "%disk0%"
    rd "%userdata%" /s /q
    if exist "%disk0p2%" (
        echo.
        echo Userdata wipe failed!
        echo [fsutils] ERROR: userdata partition wipe failed >>"%logfile%"
        goto execdone
    )
    echo [fsutils] INFO: userdata wipe successful >>"%logfile%"
    echo Wipe succeeded.
    echo.
    goto reboot
)
goto :eof

:: DevTools

:mountsys
if not exist "%usrmods%/devtools.mfm" (goto nocommand)
call :cmdok
title MicroflashOS System Partition Mounter
if not exist "%disk0p1%/" (
    echo System partition not found!
    echo [mountsys] ERROR: system partition not found >>"%logfile%"
    goto execdone
)
echo Mounting disk0p1...
echo.
cd /d "%disk0p1%/"
echo [mountsys] INFO: mounted system partition >>"%logfile%"
echo The system partition has been made accessible to the current user.
echo.
echo Modifying the system partition directly may break your device.
echo Use with caution!
goto execdone

:modules
if not exist "%usrmods%/devtools.mfm" (goto nocommand)
call :cmdok
echo [modules] INFO: listing installed modules... >>"%logfile%"
echo Core modules:
echo.
dir /a:-d /b "%disk0p1%/"
echo.
echo User modules:
echo.
dir /a:-d /b "%usrmods%/"
goto execdone

:toggles
if not exist "%usrmods%/devtools.mfm" (goto nocommand)
call :cmdok
if "%1"=="" (
    echo Manage your toggles.
    echo.
    echo Usage:
    echo.
    echo toggles [create/delete/enabled/list] [toggle]
    echo [toggle-manager] ERROR: no option selected >>"%logfile%"
    goto execdone
)
if "%1"=="create" (
    if "%2"=="" (
        echo Please enter a toggle name.
        echo [toggle-manager] ERROR: no toggle specified >>"%logfile%"
        goto execdone
    )
    echo "%2">"%toggles%/%2"
    if not exist "%toggles%/%2" (
        echo Failed to write toggle "%2"!
        echo [toggle-manager] ERROR: could not write toggle "%2" >>"%logfile%"
        echo.
        goto execdone
    )
    echo Toggle "%2" written.
    echo [toggle-manager] INFO: written toggle "%2" >>"%logfile%"
    goto execdone
)
if "%1"=="delete" (
    if "%2"=="" (
        echo Please enter a toggle name.
        echo [toggle-manager] ERROR: no toggle specified >>"%logfile%"
        goto execdone
    )
    if not exist "%toggles%/%2" (
        echo Toggle "%2" does not exist!
        echo [toggle-manager] ERROR: toggle "%2" nonexistent >>"%logfile%"
        goto execdone
    )
    del "%toggles%/%2" /f /q
    if exist "%toggles%/%2" (
        echo Failed to delete toggle "%2"!
        echo [toggle-manager] ERROR: could not delete toggle "%2" >>"%logfile%"
        goto execdone
    )
    echo Toggle "%2" deleted.
    echo [toggle-manager] INFO: deleted toggle "%2" >>"%logfile%"
    goto execdone
)
if "%1"=="enabled" (
    echo Enabled toggles:
    echo [toggle-manager] INFO: listing enabled toggles... >>"%logfile%"
    echo.
    dir /a:-d /b "%toggles%/"
    goto execdone
)
if "%1"=="list" (
    echo Toggles in MicroflashOS as of this version [%mfosver%]:
    echo [toggle-manager] INFO: listing available toggles... >>"%logfile%"
    echo.
    echo Tweaks:
    echo.
    echo showdir: Shows current directory in command line before prompt
    echo incognito: Disables writing to the command history file
    echo allowdisabled: Allow using disabled commands
    echo.
    echo Debugging tools:
    echo.
    echo slowboot: Add pauses during boot sequence
    echo echoon: Disables echo OFF so command that generated shell output is shown
    echo noclear: Disable clearing shell output (this also affects the "clear" command
    echo nolog: Disables system logging functions within MicroflashOS
    goto execdone
)
echo Invalid arguments!
echo [toggle-manager] ERROR: invalid arguments >>"%logfile%"
goto execdone

:: Package manager functions

:mfpkg
if not exist "%disk0p1%/mfpkg.mcm" (goto nocommand)
call :cmdok
title MicroflashOS Package Manager
setlocal enabledelayedexpansion
if "%1"=="list" (
    echo Installed packages:
    echo.
    dir /a:-d /b "%pkgmeta%/"
    echo [mfpkg] INFO: listed installed packages >>"%logfile%"
    endlocal
    goto execdone
)
if "%1"=="available" (
    echo Repository: %pkgrepo%
    echo.
    echo ID 001: MicroflashOS DevTools
    echo ID 002: F145HBR34K jailbreak
    echo ID 003: WinFlash Compatibility Layer
    echo ID 004: nuke
    echo ID 005: MicroflashOS Dumper
    echo ID 006: Virtual System Disk Mounter
    echo [mfpkg] INFO: showing details for repository "%pkgrepo%" >>"%logfile%"
    endlocal
    goto execdone
)
if "%1"=="install" (
    if "%2"=="" (
        echo No package ID specified.
        echo [mfpkg] ERROR: no package ID specified >>"%logfile%"
        endlocal
        goto execdone
    )
    set "pkgtarget=%2"
    set "pkgcmd=mfpkg-dl-!pkgtarget!"
    title Finding package...
    set "pkgfound=false"
    for /f "tokens=1 delims=:" %%A in ('findstr /r "^:" "%~f0"') do (
        if /i "%%A"=="!pkgcmd!" set "pkgfound=true"
    )
    if "!pkgfound!"=="false" (
        echo Package ID is invalid.
        echo [mfpkg] ERROR: installation pID invalid >>"%logfile%"
        endlocal
        goto execdone
    )
    set "pkgfound="
    goto !pkgcmd!
)
if "%1"=="uninstall" (
    if "%2"=="" (
        echo No package ID specified.
        echo [mfpkg] ERROR: no package ID specified >>"%logfile%"
        endlocal
        goto execdone
    )
    set "pkgtarget=%2"
    set "pkgcmd=mfpkg-rm-!pkgtarget!"
    title Finding package...
    set "pkgfound=false"
    for /f "tokens=1 delims=:" %%A in ('findstr /r "^:" "%~f0"') do (
        if /i "%%A"=="!pkgcmd!" set "pkgfound=true"
    )
    if "!pkgfound!"=="false" (
        echo Package ID is invalid.
        echo [mfpkg] ERROR: installation pID invalid >>"%logfile%"
        goto execdone
    )
    set "pkgfound="
    goto !pkgcmd!
)
echo Invalid arguments.
echo [mfpkg] ERROR: invalid arguments >>"%logfile%"
goto execdone

:: Installers

:mfpkg-dl-001
if not exist "%disk0p1%/mfpkg.mcm" (goto nocommand)
title MicroflashOS Package Manager
echo Downloading DevTools (pID 001)
echo [mfpkg] INFO: downloading %pkgtarget% >>"%logfile%"
echo.
echo Executing installer...
echo.
title MicroflashOS DevTools Installer
echo Installing DevTools...
echo.
echo MicroflashOS Developer Tools [%mfosver%]>"%usrmods%/devtools.mfm"
if not exist "%usrmods%/devtools.mfm" (
    echo Failed to install DevTools user module.
    echo [mfpkg] ERROR: failed to install /%sysdir%/%modsdir%/devtools.mfm >>"%logfile%"
    endlocal
    goto execdone
)
echo %pkgrepo%>"%pkgmeta%/001-DevTools"
if not exist "%pkgmeta%/001-DevTools" (goto inregfail)
echo Installed successfully.
echo Developer commands have been added to the help section.
endlocal
echo.
goto reboot

:mfpkg-dl-002
if not exist "%disk0p1%/mfpkg.mcm" (goto nocommand)
title MicroflashOS Package Manager
echo Downloading F145HBR34K (pID 002)
echo [mfpkg] INFO: downloading %pkgtarget% >>"%logfile%"
echo.
echo Executing installer...
echo.
title F145HBR34K Installer
if not exist "%usrmods%/devtools.mfm" (goto nodev)
echo F145HBR34K version: %fbver%
echo MicroflashOS version: %mfosver%
echo.
echo Installing F145HBR34K...
echo.
echo F145HBR34K jailbreak [%mfosver%]>"%usrmods%/flashbreak.mfm"
if not exist "%usrmods%/flashbreak.mfm" (
    echo Failed to install F145HBR34K user module.
    echo [mfpkg] ERROR: failed to install /%sysdir%/%modsdir%/flashbreak.mfm >>"%logfile%"
    goto execdone
)
echo %pkgrepo%>"%pkgmeta%/002-F145HBR34K"
if not exist "%pkgmeta%/002-F145HBR34K" (goto inregfail)
echo Installed successfully.
endlocal
echo.
goto reboot

:mfpkg-dl-003
if not exist "%disk0p1%/mfpkg.mcm" (goto nocommand)
title MicroflashOS Package Manager
echo Downloading WinFlash Compatibility Layer (pID 003)
echo [mfpkg] INFO: downloading %pkgtarget% >>"%logfile%"
echo.
echo Microsoft Windows Compatibility Layer for MicroflashOS>"%pkgdir%/winflash.mfp"
if not exist "%pkgdir%/winflash.mfp" (goto insfail)
echo %pkgrepo%>"%pkgmeta%/003-WinFlash"
if not exist "%pkgmeta%/003-WinFlash" (goto inregfail)
goto instdone

:mfpkg-dl-004
if not exist "%disk0p1%/mfpkg.mcm" (goto nocommand)
title MicroflashOS Package Manager
echo Downloading Nuke (pID 004)
echo [mfpkg] INFO: downloading %pkgtarget% >>"%logfile%"
echo.
echo MicroflashOS self-destruct tool by Kenneth White>"%pkgdir%/nuke.mfp"
if not exist "%pkgdir%/nuke.mfp" (goto insfail)
echo %pkgrepo%>"%pkgmeta%/004-Nuke"
if not exist "%pkgmeta%/004-Nuke" (goto inregfail)
goto instdone

:mfpkg-dl-005
if not exist "%disk0p1%/mfpkg.mcm" (goto nocommand)
title MicroflashOS Package Manager
echo Downloading dumper (pID 005)
echo [mfpkg] INFO: downloading %pkgtarget% >>"%logfile%"
echo.
echo MicroflashOS Dumper by nsp>"%pkgdir%/dumper.mfp"
if not exist "%pkgdir%/dumper.mfp" (goto insfail)
echo %pkgrepo%>"%pkgmeta%/005-dumper"
if not exist "%pkgmeta%/005-dumper" (goto inregfail)
goto instdone

:mfpkg-dl-006
if not exist "%disk0p1%/mfpkg.mcm" (goto nocommand)
title MicroflashOS Package Manager
echo Downloading mountvirt (pID 006)
echo [mfpkg] INFO: downloading %pkgtarget% >>"%logfile%"
echo.
echo Virtual System Disk Mounter by GigaflashOS Devs>"%pkgdir%/mountvirt.mfp"
if not exist "%pkgdir%/mountvirt.mfp" (goto insfail)
echo %pkgrepo%>"%pkgmeta%/006-mountvirt"
if not exist "%pkgmeta%/006-mountvirt" (goto inregfail)
goto instdone

:: Uninstallers

:mfpkg-rm-001
if not exist "%usrmods%/devtools.mfm" (goto nocommand)
call :cmdok
title MicroflashOS DevTools Uninstaller
echo Uninstalling DevTools...
echo.
call :userauth
echo.
echo [devtools] INFO: begin uninstallation >>"%logfile%"
cd /d "%usrmods%/"
del devtools.mfm /f
if exist "%usrmods%/devtools.mfm" (
    echo Failed to delete DevTools user module!
    echo [devtools] ERROR: could not delete devtools user module >>"%logfile%"
    goto execdone
)
echo [devtools] INFO: deleted user module devtools.mfm >>"%logfile%"
cd /d "%pkgmeta%/"
del 001-DevTools /f
if exist "%pkgmeta%/001-DevTools" (goto unregfail)
echo [devtools] INFO: unregistered devtools package >>"%logfile%"
echo DevTools uninstalled!
echo You will not be able to use developer commands anymore.
echo [devtools] INFO: uninstallation complete >>"%logfile%"
echo.
goto reboot

:mfpkg-rm-002
if not exist "%usrmods%/flashbreak.mfm" (goto nocommand)
call :cmdok
if not exist "%usrmods%/devtools.mfm" (call :nodev)
echo F145HBR34K Uninstaller
echo F145HBR34K version: %fbver%
echo MicroflashOS version: %mfosver%
echo.
echo Uninstalling jailbreak...
echo.
call :userauth
echo.
cd /d "%usrmods%"
del flashbreak.mfm /f /q
if exist "%usrmods%/flashbreak.mfm" (
    echo Failed to delete F145HBR34K user module!
    echo [flashbreak] ERROR: could not delete flashbreak user module >>"%logfile%"
    goto execdone
)
echo [flashbreak] INFO: deleted user module flashbreak.mfm >>"%logfile%"
cd /d "%pkgmeta%"
del 002-F145HBR34K /f /q
if exist "%pkgmeta%/002-F145HBR34K" (goto unregfail)
echo.
echo Jailbreak uninstalled!
echo.
echo All F145HBR34K commands will be invalidated.
echo [flashbreak] INFO: uninstallation complete >>"%logfile%"
echo.
goto reboot

:mfpkg-rm-003
if not exist "%disk0p1%/mfpkg.mcm" (goto nocommand)
title MicroflashOS Package Manager
if not exist "%pkgmeta%/003-WinFlash" (call :nopkg)
echo Uninstalling WinFlash Compatibility Layer (pID 003)
echo.
set "curdir=%cd%"
cd /d "%pkgdir%/"
del winflash.mfp /f /q
if exist "%pkgdir%/winflash.mfp" (goto uninsfail)
cd /d "%pkgmeta%"
del "003-WinFlash" /f /q
if exist "%pkgmeta%/003-WinFlash" (goto unregfail)
goto uninstdone

:mfpkg-rm-004
if not exist "%disk0p1%/mfpkg.mcm" (goto nocommand)
title MicroflashOS Package Manager
if not exist "%pkgmeta%/004-Nuke" (call :nopkg)
echo Uninstalling Nuke (pID 004)
echo.
set "curdir=%cd%"
cd /d "%pkgdir%/"
del nuke.mfp /f /q
if exist "%pkgdir%/nuke.mfp" (goto uninsfail)
cd /d "%pkgmeta%"
del "004-Nuke" /f /q
if exist "%pkgmeta%/004-Nuke" (goto unregfail)
goto uninstdone

:mfpkg-rm-005
if not exist "%disk0p1%/mfpkg.mcm" (goto nocommand)
title MicroflashOS Package Manager
if not exist "%pkgmeta%/005-dumper" (call :nopkg)
echo Uninstalling dumper (pID 006)
echo.
set "curdir=%cd%"
cd /d "%pkgdir%/"
del dumper.mfp /f /q
if exist "%pkgdir%/dumper.mfp" (goto uninsfail)
cd /d "%pkgmeta%"
del "005-dumper" /f /q
if exist "%pkgmeta%/005-dumper" (goto unregfail)
goto uninstdone

:mfpkg-rm-006
if not exist "%disk0p1%/mfpkg.mcm" (goto nocommand)
title MicroflashOS Package Manager
if not exist "%pkgmeta%/006-mountvirt" (call :nopkg)
echo Uninstalling mountvirt (pID 006)
echo.
set "curdir=%cd%"
cd /d "%pkgdir%/"
del mountvirt.mfp /f /q
if exist "%pkgdir%/mountvirt.mfp" (goto uninsfail)
cd /d "%pkgmeta%"
del "006-mountvirt" /f /q
if exist "%pkgmeta%/006-mountvirt" (goto unregfail)
goto uninstdone

:: Custom packages

:nuke
if not exist "%pkgdir%/nuke.mfp" (goto nocommand)
call :cmdok
if not exist "%usrmods%/devtools.mfm" (goto nodev)
title Nuke
echo Nuking system disk. ALL DATA WILL BE WIPED!
echo.
call :userauth
echo.
if exist "%disk0p1%" (
    rd "%disk0p1%" /s /q
    echo System disk nuked!
    goto execdone
)
echo System disk not found!
goto execdone

:dumper
if not exist "%pkgdir%/dumper.mfp" (goto nocommand)
call :cmdok
if not exist "%usrmods%/devtools.mfm" (goto nodev)
if "%fbloaded%" NEQ "yessir" (goto nofb)
title MicroflashOS Dumper
echo MicroflashOS Dumper by nsp
echo.
if exist "%disk0p1%" (
  echo System disk mounted.
  echo.
  echo Dumping current MicroflashOS system disk to %~dp0dump
  echo.
  xcopy "%disk0%" "%~dp0dump\" /w /e /f
  goto execdone
) 
echo Could not find system disk. System may be corrupt.
echo Please enter recovery mode to repair your system.
goto execdone

:winflash
if not exist "%pkgdir%/winflash.mfp" (goto nocommand)
call :cmdok
title WinFlash
cls
echo Type EXIT and press Enter to return to MicroflashOS.
echo.
echo [winflash] INFO: loading cmd.exe >>"%logfile%"
cmd.exe
echo [winflash] INFO: welcome back to mfos >>"%logfile%"
goto execdone

:mountvirt
if not exist "%pkgdir%/mountvirt.mfp" (goto nocommand)
call :cmdok
if not exist "%usrmods%/devtools.mfm" (goto nodev)
if "%fbloaded%" NEQ "yessir" (goto nofb)
title Virtual System Disk Mounter
if "%1"=="" (
    echo This command is used to mount a "virtual system disk".
    echo These can be obtained with the dumper, installable via pID 005.
    echo.
    echo Usage:
    echo.
    echo mountvirt [disk name]
    echo.
    echo Note: Virtual system disks must be in the same location as the Batch file!
    goto execdone
)
if not exist "%~dp0%1" (
    echo System disk not found.
    goto execdone
)
set "disk0label=%1"
echo Mounted virtual disk.
echo.
goto reboot

:: Debugging commands

:getargs
call :cmdok
echo showing maximum 3
echo.
echo raw: "%*"
echo.
echo arg1: "%1"
echo arg2: "%2"
echo arg3: "%3"
goto execdone

:getvars
call :cmdok
set
goto execdone

:: MicroflashOS Recovery

:recovery
cls
cd /d "%~dp0"
title MicroflashOS Recovery
echo.
echo Installing MicroflashOS.
call :halt

:: System disk creation

if not exist "%~dp0%disk0label%" (md "%disk0label%")
if not exist "%~dp0%disk0label%" (
    echo.
    echo Failed to format system disk!
    call :pauseexit
)
echo.
echo System disk "%disk0label%" mounted as /
cd /d "%~dp0%disk0label%"
if exist %sysdir% (rd %sysdir% /s /q)
if not exist %sysdir% (md %sysdir%)
if not exist %sysdir% (
    echo.
    echo Failed to create operating system data directory!
    call :pauseexit
)

:: Install core modules

echo.
echo Installing core modules...
echo.

echo Long-term memory [%mfosver%]>"%disk0p1%/ltmem.mcm"
if not exist "%disk0p1%/ltmem.mcm" (call :modinstfail /%sysdir%/ltmem.mcm)
echo Installed /%sysdir%/ltmem.mcm

echo Short-term memory [%mfosver%]>"%disk0p1%/stmem.mcm"
if not exist "%disk0p1%/stmem.mcm" (call :modinstfail /%sysdir%/stmem.mcm)
echo Installed /%sysdir%/stmem.mcm

echo Core MicroflashOS commands [%mfosver%]>"%disk0p1%/core.mcm"
if not exist "%disk0p1%/core.mcm" (call :modinstfail /%sysdir%/core.mcm)
echo Installed /%sysdir%/core.mcm

echo File system read/write utilities [%mfosver%]>"%disk0p1%/fsutils.mcm"
if not exist "%disk0p1%/fsutils.mcm" (call :modinstfail /%sysdir%/fsutils.mcm)
echo Installed /%sysdir%/fsutils.mcm

echo Command line [%mfosver%]>"%disk0p1%/cmd.mcm"
if not exist "%disk0p1%/cmd.mcm" (call :modinstfail /%sysdir%/cmd.mcm)
echo Installed /%sysdir%/cmd.mcm

echo MicroflashOS recovery [%mfosver%]>"%disk0p1%/recovery.mcm"
if not exist "%disk0p1%/recovery.mcm" (call :modinstfail /%sysdir%/recovery.mcm)
echo Installed /%sysdir%/recovery.mcm

echo MicroflashOS kernel.mcm [%mfosver%]>"%disk0p1%/kernel.mcm"
if not exist "%disk0p1%/kernel.mcm" (call :modinstfail /%sysdir%/kernel.mcm)
echo Installed /%sysdir%/kernel.mcm

echo MicroflashOS Ultracompacter [%mfosver%]>"%disk0p1%/compact.mcm"
if not exist "%disk0p1%/compact.mcm" (call :modinstfail /%sysdir%/compact.mcm)
echo Installed /%sysdir%/compact.mcm

echo MicroflashOS Protector [%mfosver%]>"%disk0p1%/proctector.mcm"
if not exist "%disk0p1%/proctector.mcm" (call :modinstfail /%sysdir%/proctector.mcm)
echo Installed /%sysdir%/proctector.mcm

echo MicroflashOS Package Manager [%mfosver%]>"%disk0p1%/mfpkg.mcm"
if not exist "%disk0p1%/mfpkg.mcm" (call :modinstfail /%sysdir%/mfpkg.mcm)
echo Installed /%sysdir%/mfpkg.mcm

echo Audio output [%mfosver%]>"%disk0p1%/audio.mcm"
if not exist "%disk0p1%/audio.mcm" (call :modinstfail /%sysdir%/audio.mcm)
echo Installed /%sysdir%/audio.mcm

echo Graphics subsystem [%mfosver%]>"%disk0p1%/graphics.mcm"
if not exist "%disk0p1%/graphics.mcm" (call :modinstfail /%sysdir%/graphics.mcm)
echo Installed /%sysdir%/graphics.mcm

echo All-in-one sensor package [%mfosver%]>"%disk0p1%/sensors.mcm"
if not exist "%disk0p1%/sensors.mcm" (call :modinstfail /%sysdir%/sensors.mcm)
echo Installed /%sysdir%/sensors.mcm

echo.
echo Registering MicroflashOS version...
echo.
cd /d "%~dp0%disk0label%"
echo %mfosver%>"version.txt"
if not exist "version.txt" (
    echo Failed to register MicroflashOS version!
    call :pauseexit
)

echo MicroflashOS installation complete!
echo Please re-launch the Batch script.
call :halt
exit

:: Proctector authorization

:userauth
echo [proctector] INFO: requesting user authorization >>"%logfile%"
set /p "confirmation=Type "CONFIRM" (case-sensitive) to confirm this action: "
if "%confirmation%" == "CONFIRM" (
    set "confirmation="
    set "authorized=true"
    echo [proctector] INFO: authorized >>"%logfile%"
    goto :eof
) else (
    echo.
    echo User authorization failed!
    echo [kernel] ERROR: user authorization failed >> "%logfile%"
    goto execdone
)

:: Command execution successful

:execdone
echo [cmd] INFO: command execution complete >> "%logfile%"
goto :eof

:cmdok
echo [cmd] INFO: command valid >>"%logfile%"
if not exist "%toggles%/incognito" (echo [valid] "%input%" >>"%history%")
goto :eof

:: Failed some dependency checks

:nocommand
echo Invalid command.
if not exist "%toggles%/incognito" (echo [invalid] "%input%" >>"%history%")
echo [cmd] ERROR: command "%input%" invalid >>"%logfile%"
goto :eof

:nodev
echo DevTools not found. Install pID 001.
echo [cmd] ERROR: required dependency "DevTools" is missing >>"%logfile%"
goto :eof

:nofb
echo F145HBR34K not found. Install pID 002.
echo [cmd] ERROR: required dependency "F145HBR34K" is missing >>"%logfile%"
goto :eof

:: Generic boot failure

:bootfail
echo.
title Startup Failure!
echo MicroflashOS startup failed. Entering recovery...
call :halt
echo [kernel] INFO: booting to recovery... >>"%logfile%"
echo [kernel] INFO: booting to recovery...
goto recovery

:: Recovery mode

:modinstfail
echo Failed to install module "%1"
goto :pauseexit

:: Package-related stuff

:nopkg
echo Package not installed!
goto :eof

:instdone
echo Installed package ID %pkgtarget%
echo [mfpkg] INFO: installed pID %pkgtarget% >>"%logfile%"
endlocal
goto execdone

:uninstdone
echo Uninstalled package ID %pkgtarget%
echo [mfpkg] INFO: uninstalled pID %pkgtarget% >>"%logfile%"
cd /d %curdir%
endlocal
goto execdone

:insfail
echo Failed to install package %pkgtarget%
echo [mfpkg] ERROR: failed to install pID %pkgtarget% >>"%logfile%"
endlocal
goto execdone

:inregfail
echo Failed to register package %pkgtarget%
echo [mfpkg] ERROR: failed to register pID %pkgtarget% >>"%logfile%"
endlocal
goto execdone

:uninsfail
echo Failed to uninstall package %pkgtarget%
echo [mfpkg] ERROR: failed to uninstall pID %pkgtarget% >>"%logfile%"
endlocal
goto execdone

:unregfail
echo Failed to unregister package %pkgtarget%
echo [mfpkg] ERROR: failed to unregister pID %pkgtarget% >>"%logfile%"
endlocal
goto execdone

:: Boot process

:devinitfail
echo [kdevinit] ERROR: failed to initialize "%1" >>"%logfile%"
echo Could not initialize device "%1"
goto pauseexit

:loadmodok
echo Loaded %1
echo [kmodsinit] INFO: loaded %1 >>"%logfile%"
goto :eof

:loadmodfail
echo.
echo FAIL %1
echo [kmodsinit] ERROR: failed to load %1 >>"%logfile%"
goto bootfail

:fbpatchfail
echo Module %1 not found!
echo Jailbreak unsuccessful.
echo [fb-s3init] ERROR: failed to load %1 >>"%logfile%"
set fbloaded=nope
goto bootcomplete

:slowboot
echo.
echo Slowboot toggle tripped!
call :halt
echo [bootloader] DEBUG: slowboot toggle tripped >>"%logfile%"
goto :eof

:: Common pause and exit function

:pauseexit
call :halt
exit

:halt
echo.
pause
goto :eof
