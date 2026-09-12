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

	preload:
		call install_keyboard

		mov si, spaceship_uta
		call load_asset  		; cargamos la nave con id 0

	game_loop:
		.update:
			; aun no hay limites de fps ni nada sol obucle

			call player_update

			jmp .render
		
		.render:
			call clear_back	; limpiamos backbuffer

			call player_render ; todo se dibuja en el backbuffer

			call render_buffer ; cargamos el backbuffer en el VGA

			jmp .update

	jmp $

%include "src/utils/assets.asm" ;; libreria para gestionar assets
%include "src/utils/graphics.asm" ;; libreria para dibujar jijij jeje
%include "src/utils/keyboard.asm" ;; libreria pa el teclado

;; objetos
%include "src/obj/player.asm" ;; cargamos el controlador general del jugador

data:
	drive_number db 0
	spaceship_uta db "SP_SHIP UTA"