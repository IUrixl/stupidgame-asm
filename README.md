# STUPIDGAME ASM
As its name states, this is a stupid project made just to grasp more the basics of assembly. Im not an expert, i tried to comment everything i considered important but made it in spanish (since im spanish) so i could re-read the code later on and improve it, dont be too harsh on me, i know my code could be better!


## About the runtime
This entire project runs bare-metal, the Image containing the binaries is FAT12 	formatted. The boot.asm loads the FAT at 0X9c00, the root at 0X8000, 0XAE00 is a 512 byte buffer reserved to load the first sector of each file when running "load_file" from src/utils/disk.asm, after reading the package of the file its relocated to the segment and offset specified on the package and 0XAE00 is wiped.

Everything runs in real mode, no switch to protected, 16 bits the whole time.

I'll be adding more info about how the project works!

## Execution
I haven't tried it outside an qemu, but theoretically you could mount the image to a usb (or any other device) and load it bare-metal if you use BIOS legacy (as i havent used UEFI but BIOS for the entirety of the project).

## Compilation
Made a small tool myself using batch to compile the project and run it, as i made this entire project in windows. For you in order to build it you must have fat_imgen and nasm downloaded. You can then run it on Bosch, QEMU, ... as you prefer, up to you!

Once you made sure you have the tools needed for compilation just open a CMD in the folder and run "build", it will automatically build the image and execute it using run.bat (essentially just a qemu-system-i386 command i was lazy to retype everytime lmao)

You can also build it with your own toolchain or whatever, it should work as long as you make it a FAT12 image.