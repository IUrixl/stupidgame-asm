org 0x0000
bits 16

package:
	.magic: db "BIN" ; firma estupida realmente, pero bueno, 3 bytes reservados para darle un toque asi profesional
	.segment: dw 0x1000
	.offset: dw 0x0000
	.run: db 1

_run:
	push cs
	pop ds

	mov [drive_number], dl ; cargamos drive number pasado por el bootloader

	xor ax, ax
	xor bx, bx
	xor cx, cx
	xor dx, dx

	; ponemos el modo VGA 320x200, seguun rbil es 13h.
	call set_mode

	.preload:
		mov si, spaceship_uta
		call load_asset  		; cargamos la nave con id 0

	.render:
		; de momento solo quiero cargar la nave, despues hago el loop
		mov ax, 0 ; offset x
		mov bh, 0 ; offset y
		mov bl, 0 ; asset id
		call render_sprite

	jmp $

%include "src/utils/assets.asm" ;; libreria para gestionar assets
%include "src/utils/graphics.asm" ;; libreria para dibujar jijij jeje

data:
	drive_number db 0
	spaceship_uta db "SP_SHIP UTA"