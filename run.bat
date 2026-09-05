@echo off

qemu-system-i386 -drive format=raw,file=build/result.img -monitor stdio && exit /b