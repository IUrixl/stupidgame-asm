org 0x0000
bits 16

package:
	.signature: db "URI" ; firma estupida realmente, pero bueno, 3 bytes reservados para darle un toque asi profesional
	.segment: dw 0x1000
	.offset: dw 0x0000
	.run: db 1

_run:
	push cs
	pop ds

	xor ax, ax
	xor bx, bx
	xor cx, cx
	xor dx, dx

	; pequeño test
	mov si, data.welcome_msg
	call print

	jmp $

%include "src/utils/print.asm"

data:
	.welcome_msg: db "Hola desde el juego!", 0
