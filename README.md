# STUPIDGAME ASM
As its name states, this is a stupid project made just to grasp more the basics of assembly. Im not an expert, i tried to comment everything i considered important but made it in spanish (since im spanish) so i could re-read the code later on and improve it, dont be too harsh on me, i know my code could be better!

## About the runtime
This entire project runs bare-metal, the Image containing the binaries is FAT12 formatted. The boot.asm loads the first FAT at 0X9c00, the root at 0X8000, 0XAE00 is a 512 byte buffer reserved to load the first sector of each file when running "load_file" from src/utils/disk.asm, after reading the package of the file its relocated to the segment and offset specified on the package and 0XAE00 is wiped.

Everything runs in real mode, no switch to protected, 16 bits the whole time.

This project has its own file extensions, such as UTA (Uriel Texture Assembly) for 320x200 VGA textures. They are then loaded into 0x30000 by the asset loaded and saved in a asset table located in 0x20000 that adds the asset an ID and their entry segment:offset. 

**If you want to reuse the asset loader and the graphics library then you might be interested on checking how the sprites are made! [check it now](#making-textures)** 

For the keyboard controller src/utils/keyboard.asm modifies the IVT 0000:0024 hooking a custom keyboard function that detects the make / break code of the key and toggles its state on a 128 byte reserved table. 

I'll be adding more info about how the project works!

## Execution
I haven't tried it outside qemu, but theoretically you could mount the image to a usb (or any other device) and load it bare-metal if you use BIOS legacy (as i havent used UEFI but BIOS for the entirety of the project).

## Compilation
Made a small tool myself, using batch, to compile the project and run it, as i made this entire project in windows. For you in order to build it you must have fat_imgen and nasm downloaded. You can then run it on Bosch, QEMU, ... as you prefer, up to you!

Once you made sure you have the tools needed for compilation just open a CMD in the folder and run "build", it will automatically build the image and execute it using run.bat (essentially just a qemu-system-i386 command i was lazy to retype everytime lmao)

You can also build it with your own toolchain or whatever, it should work as long as you make it a FAT12 image.

### Making textures
Textures in this project are UTA files, as stated [here](#about-the-runtime). In order to make one you must make a pixelart, export it to .PNG and use the official PNG to UTA conversor toolchain in this [repository](https://github.com/IUrixl/uta-conversor). Don't make huge images as the conversor is pretty simple and we are limited to the 13H VGA color palette.

## Bibliographic Reference
All the information i used for this project is contained within these webs.

[fd.lod.bz Ralf's Brown Interrupt List](https://fd.lod.bz/rbil/interrup/bios/1600.html) (contains really useful info).\
[fountainware Bios Key Codes](https://www.fountainware.com/EXPL/bios_key_codes.htm)\
[os.dev](https://wiki.osdev.org) (this website details a lot of concepts, such as the make/break, interrupt vector list, etc).\
[wikipedia Mode 13h](https://en.wikipedia.org/wiki/Mode_13h)
