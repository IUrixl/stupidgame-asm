@echo off
setlocal EnableDelayedExpansion

echo [1/4] Preparing...
set "src=src"
set "bins=bins"
set "assets=assets"
set "target=build\result.img"

if exist bins rmdir /s /q bins
mkdir bins

if exist build rmdir /s /q build
mkdir build

rem asm to bin
echo [2/4] Starting to compile assembly files...

for %%F in (!src!\*.asm) do (
	set "_file=%%F"
	set "_rfile=%%~nxF"
	set "_rfile=!_rfile:~0,-4!"

	if !_failed! neq 1 ( nasm -f bin !_file! -o !bins!\%%~nF.bin )
	rem if !_failed! neq 1 ( nasm -f bin !_file! -o !bins!\%%~nF.bin -l !bins!\%%~nF.lst )

	if errorlevel 1 (
		echo. 
		echo IURIXL TOOLCHAIN -------------------
		echo Aborted build: Error while compiling
		echo ------------------------------------
		set "_failed=1"
		exit /b
	) else (
		echo(      -^> Compiled !_file! to bins\!_rfile!.bin
	)
)

if "!_failed!"==1 exit /b 1

rem bin to img
echo [3/4] Attempting to build FAT12 image...
fat_imgen -c -f !target!

if errorlevel 1 (
	echo IURIXL TOOLCHAIN --------------------------------
	echo Aborted build: Error while making the FAT12 image
	echo -------------------------------------------------
	exit /b 1
) else (
echo(      -^> Generated empty FAT12 image !target!
)

echo(      -^> Attempting to add binaries to the image...

for %%F in (!bins!\*.bin) do (
	set "_file=%%F"
	set "_rfile=%%~nxF"

	if "!_rfile:~0,-4!" == "boot" (
		echo(      -^> Found and attempting to load boot sector into the image
		fat_imgen -m -f !target! -s !_file!
	) else (
		echo(      -^> Found binary !_file!, attempting to add to the image...
		fat_imgen -m -f !target! -i !_file!
	)
)

rem assets to img
if exist !assets! (
	for %%F in (!assets!\*) do (
		set "_file=%%F"
		set "_rfile=%%~nxF"

		echo(      -^> Found asset: !_file!, attempting to add to the image...
		fat_imgen -m -f !target! -i !_file!
	)
)

rem execution
endlocal
echo [4/4] Calling run command...
call run