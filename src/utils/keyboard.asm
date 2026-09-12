install_keyboard:
	; necesitamos sobreescribir el IVT del teclado en 0x0000:0x0024
	; usaremos los make y break codes de los teclados recibidos en el puerto 0x60
	push ax
	push es
	push di

	mov ax, 0x0000
	mov es, ax ; apuntamos segment a 0000

	mov ax, 0x0024 
	mov di, ax ; apuntamos offset a 0x0024, donde esta el vector del teclado

	; el motivo de por que se escribe offset:segment es por la estructura Little Endian y toda la paranoia, pero a mi me gusta guardarlo
	; por segment:offset, la que luego cargo el registro es y di en ese orden.

	; guardamos el vector original para hookearlo despues
	mov ax, [es:di] 
	mov word [keyboard.original_vector_offset], ax ; cargamos los dos primeros bytes que son el segment

	mov ax, [es:di+2]
	mov word [keyboard.original_vector_segment], ax

	; hookeamos la funcion
	cli

	mov ax, .keyboard_hook
	mov [es:di], ax ;; offset

	mov ax, cs ;; segmento
	mov [es:di+2], ax

	sti

	pop di
	pop es
	pop ax
	ret

	.keyboard_hook:
		push ax
		push bx
		push es
		push di

		in al, 0x60 ; obtenemos el scan code
		mov ah, al ; clonamos el valor

		; make y break:
		; 8 bit => make o break
		; 1-7 bit => scan code

		; miramos si es scan o break
		; mascara => and al 1000 0000
		and ah, 0x80

		; cogemos el scan code
		; mascara => and ah 0111 1111
		and al, 0x7f

		mov di, keyboard.keys_state
		mov bh, 0
		mov bl, al ; pasamos al a un registro word

		cmp ah, 0x80 ; miramos si ha sido release
		je .released

		mov ah, 1
		jmp .save_state

		.released:
			mov ah, 0

		.save_state:
		mov byte [di + bx], ah ; pasamos el valor, al comprovar en nuestras funciones, si el valor de la tabla es de 0 entonces esta presionada.

		mov al, 0x20
		out 0x20, al

		pop di
		pop es
		pop bx
		pop ax
		iret ; interrupt return

get_key_state: ; al = scancode -> al = return
	push bx

	mov bh, 0
	mov bl, al ; guardamos scancode

	mov al, [keyboard.keys_state + bx]

	pop bx
	ret

keyboard:
	.original_vector_segment: dw 0
	.original_vector_offset: dw 0
	.keys_state:
		times 128 db 0 ; reservamos 128 bytes para tener un mapa